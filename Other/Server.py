from flask import Flask, jsonify, request
import MySQLdb
import gurobipy as gp
from gurobipy import GRB

# Create a new model
m = gp.Model("TeamSchedule")

app = Flask(__name__)

def get_database_connection():
    return MySQLdb.connect(host="localhost",
                           user="root",
                           passwd="12345",
                           db="Capstone_2024")

@app.route('/league', methods=['POST'])
def receive_teams():
    league_id = request.json
    # Process the received data as needed
    print("Received league id:", league_id)

    try:
        db = get_database_connection()
        cur = db.cursor()
        cur.execute("SELECT TEAM_ID FROM TEAM_INFO WHERE league_id = %s", (league_id,))
        team_names = [row[0] for row in cur.fetchall()]
        print(team_names)
    except Exception as e:
        print("error", str(e))
    finally:
        cur.close()
        db.close()

    num_teams = len(team_names)
    num_weeks = 2 * (num_teams - 1)
    end_of_week = (num_teams - 1)
    matches_per_week = num_teams / 2

    # Decision Variables
    T = range(num_teams)
    W = range(num_weeks)
    x = m.addVars(T, T, W, vtype=GRB.BINARY, name="x")  # x[i, j, k] represents if team i plays against team j in week k

    # Define break variables
    y_home = m.addVars(T, W, vtype=GRB.BINARY, name="y_home")  # y_home[i, k] = 1 if team i has a home break in week k
    y_away = m.addVars(T, W, vtype=GRB.BINARY, name="y_away")  # y_away[j, k] = 1 if team j has an away break in week k

    # Constraints
    # Each team plays against every other team exactly twice (once in first half, once in second half)
    for i in T:
        for j in range(i + 1, num_teams):
            m.addConstr(gp.quicksum(x[i, j, k] + x[j, i, k] for k in range(num_weeks // 2)) == 1)  # First half
            m.addConstr(
                gp.quicksum(x[i, j, k] + x[j, i, k] for k in range(num_weeks // 2, num_weeks)) == 1)  # Second half

    # Each team plays exactly one home or one away match per week
    for k in W:
        for i in T:
            m.addConstr(gp.quicksum(x[i, j, k] for j in T) + gp.quicksum(x[j, i, k] for j in T) == 1)

    # Ensure each team plays every week
    for i in T:
        m.addConstr(gp.quicksum(x[i, j, k] + x[j, i, k] for j in T for k in W) == num_weeks)

    # Constraints to define breaks
    for i in T:
        for k in range(1, num_weeks):
            m.addConstr(y_home[i, k] >= gp.quicksum(x[i, j, k - 1] for j in T) + gp.quicksum(x[i, j, k] for j in T) - 1)
            m.addConstr(y_away[i, k] >= gp.quicksum(x[j, i, k - 1] for j in T) + gp.quicksum(x[j, i, k] for j in T) - 1)

    # Fixture mirroring constraints (ensure second half is a mirror of the first half)
    for i in T:
        for j in range(i + 1, num_teams):
            for k in range(num_weeks // 2):
                m.addConstr(x[i, j, k] == x[j, i, k + num_weeks // 2])
                m.addConstr(x[j, i, k] == x[i, j, k + num_weeks // 2])

    # Objective function to minimize breaks
    m.setObjective(gp.quicksum(y_home[i, k] + y_away[i, k] for i in T for k in W), GRB.MINIMIZE)

    # Print model size
    print(f"Number of variables: {m.NumVars}")
    print(f"Number of constraints: {m.NumConstrs}")

    # Optimize the model
    try:
        m.optimize()
    except gp.GurobiError as e:
        print("Gurobi Error:", str(e))
        return jsonify({'error': str(e)}), 500

    limiter = 0
    fixture = []
    week = matches_per_week
    # Print the results
    if m.status == GRB.OPTIMAL:
        print("Optimal Schedule:")
        for k in W:
            # print(f"Week {k+1}:")
            for i in T:
                for j in T:
                    if x[i, j, k].x > 0.5:
                        if limiter < end_of_week * matches_per_week:
                            fixture.append([team_names[i], team_names[j]])
                            limiter += 1
        fixtureresult = []
        fixtureresultplain = []
        fixtureresulttexthome = ''
        fixtureresulttextaway = ''
        for match in fixture:
            if week % matches_per_week == 0:
                print(f"Week {int(week / matches_per_week)}:")
                fixtureresultplain.append((fixtureresulttexthome, fixtureresulttextaway, int(week / matches_per_week)))
                fixtureresulttexthome = ''
                fixtureresulttextaway = ''
            print(f"Team {match[0]} (Home) vs. Team {match[1]} (Away)")
            fixtureresulttexthome += str(match[0])
            fixtureresulttextaway += str(match[1])
            fixtureresult.append((match[0], match[1], int(week / matches_per_week)))
            week += 1
        for match in fixture:
            if week % matches_per_week == 0:
                print(f"Week {int(week / matches_per_week)}:")
                fixtureresultplain.append((fixtureresulttexthome, fixtureresulttextaway, int(week / matches_per_week)))
                fixtureresulttexthome = ''
                fixtureresulttextaway = ''
            print(f"Team {match[1]} (Home) vs. Team {match[0]} (Away)")
            fixtureresulttexthome += str(match[1])
            fixtureresulttextaway += str(match[0])
            fixtureresult.append((match[1], match[0], int(week / matches_per_week)))
            week += 1

        for i in fixtureresult:
            insert_fixture_into_database(league_id,i[0],i[1],i[2])

        # Define breaks
        breaks = []

        for match in fixtureresult:
            if fixtureresultplain[match[2] - 1][0].find(str(match[0])) >= 0:
                breaks.append((match[0], match[2]))
            if fixtureresultplain[match[2] - 1][1].find(str(match[1])) >= 0:
                breaks.append((match[1], match[2]))

        # Print breaks
        print("Breaks:")
        for break_info in breaks:
            print(f"Team {break_info[0]} has a break in Week {break_info[1]}")
            insert_break_into_database(league_id,break_info[0],break_info[1])

        print(f"Total Break Count: {len(breaks)}")
        response = league_id

    else:
        print("No solution found.")
        response = -1

    print(response)
    return jsonify(response)


def insert_fixture_into_database(league_id, home_team_id, away_team_id, match_week):
    try:
        db = get_database_connection()
        cur = db.cursor()
        cur.execute(
            "INSERT INTO MATCH_INFO (LEAGUE_ID, HOMETEAM_ID, AWAYTEAM_ID, MATCH_WEEK) VALUES (%s, %s, %s, %s)",
                    (league_id, home_team_id, away_team_id, match_week))
        db.commit()
    except Exception as e:
        print("Error inserting BREAK_TEAM_INFO into the database:", e)
        db.rollback()
    finally:
        cur.close()

def insert_break_into_database(league_id, team_id, match_week):
    try:
        db = get_database_connection()
        cur = db.cursor()
        cur.execute(
            "INSERT INTO BREAK_TEAM_INFO VALUES (%s, %s, %s)",
            (league_id, team_id, match_week))
        db.commit()
    except Exception as e:
        print("Error inserting BREAK_TEAM_INFO into the database:", e)
        db.rollback()
    finally:
        cur.close()



if __name__ == '__main__':
    app.run(debug=True)

import tkinter as tk
from tkinter import filedialog
import os
import pandas as pd

class Application(tk.Frame):              
    def __init__(self, master=None):
        tk.Frame.__init__(self, master)
        self.grid()
        self.createWidgets()
        self.resultsfile = ""
        self.startlistfile = ""

    def createWidgets(self):
        window = self.winfo_toplevel()
        window.geometry("600x138")

        self.startListButton = tk.Button(self, text='Select Start List', command=self.selectStartList)      
        self.resultsButton = tk.Button(self, text='Select Results File', command=self.selectResults) 
        self.calculateButton = tk.Button(self, text='Calculate Points', command=self.calculate)     

        self.startListLabel = tk.Label(self)
        self.resultsLabel = tk.Label(self)

        self.startListButton.grid(column=0, row=0, padx=10, pady=10, sticky=tk.E+tk.W)
        self.resultsButton.grid(column=0, row=1, padx=10, pady=10, sticky=tk.E+tk.W)
        self.calculateButton.grid(column=0, row=2, columnspan = 2, padx=10, pady=10, sticky=tk.E+tk.W)
        self.startListLabel.grid(column=1, row=0, stick=tk.W)
        self.resultsLabel.grid(column=1, row=1, sticky=tk.W)

    def selectStartList(self):
        self.startlistfile = filedialog.askopenfilename(title='Select Start List File')
        self.startListLabel.config(text = self.startlistfile)

    def selectResults(self):
        self.resultsfile = filedialog.askopenfilename(title='Select Results File')
        self.resultsLabel.config(text = self.resultsfile)

    def calculate(self):
        self.savefolder = filedialog.askdirectory(title='Select Output Folder')
        if len(self.savefolder) > 0:
            self.calculate_points(self.startlistfile, self.resultsfile, self.savefolder)
        

    def calculate_points(self, startlist, results, savefolder):
        # load list of racers and teams
        racers = pd.read_csv(startlist)

        # fix column names
        racers.columns.values[1] = 'BIB'
        racers.columns.values[4] = 'NAME'
        racers.columns.values[6] = 'TIER'
        racers.columns.values[7] = 'TEAM'

        # get rid of rows where Name, Team, Club, or Bib are not filled in
        racers.dropna(subset = ['NAME', 'TIER', 'TEAM', 'BIB'], inplace=True)

        # get times file
        times = pd.read_csv(results, index_col = False, names=['BIB', 'NAME', 'RUN1', 'RUN2'], encoding='ANSI')

        # replace DNF, DSQ, DNS by 999, 888, 777
        times['RUN1'].replace(to_replace = ['DNF'], value = 999.0, inplace=True)
        times['RUN1'].replace(to_replace = ['DSQ'], value = 888.0, inplace=True)
        times['RUN1'].replace(to_replace = ['DNS'], value = 777.0, inplace=True)
        times['RUN1'].replace(to_replace = ['DNS'], value = 777.0, inplace=True)
        times['RUN1'].fillna(777.0, inplace=True)
        times['RUN2'].replace(to_replace = ['DNF'], value = 999.0, inplace=True)
        times['RUN2'].replace(to_replace = ['DSQ'], value = 888.0, inplace=True)
        times['RUN2'].replace(to_replace = ['DNS'], value = 777.0, inplace=True)
        times['RUN2'].replace(to_replace = ['DNS'], value = 777.0, inplace=True)
        times['RUN2'].fillna(777.0, inplace=True)

        # convert BIB, RUN1, RUN2 to number types
        times['BIB'] = pd.to_numeric(times['BIB'])
        times['RUN1'] = pd.to_numeric(times['RUN1'])
        times['RUN2'] = pd.to_numeric(times['RUN2'])

        # select best time
        times['BEST'] = times[['RUN1', 'RUN2']].min(axis=1)

        # drop names from times list
        times.drop('NAME', axis=1, inplace=True)

        # attach times to racers in one table
        results = racers.merge(times, on='BIB')

        # get rid of columns we don't need
        results = results[['BIB', 'NAME', 'TIER', 'TEAM', 'RUN1', 'RUN2', 'BEST']]

        # get list of tier groups
        tiers = results['TIER'].unique().tolist()

        # create points column
        results['POINTS'] = 0

        # set results to index using bib
        results.set_index('BIB', inplace=True)

        # assign points based on position in each tier group
        for index, tier in enumerate(tiers):
            # select race subset by tier group
            subrace = results[results['TIER'] == tier]
            # sort by best time
            subrace = subrace.sort_values('BEST')
            # create points column
            minval = 10 - len(subrace)
            points = list(range(10, minval, -1))
            points = [0 if x < 0 else x for x in points]
            subrace['POINTS'] = points
            # merge points into results
            subrace = subrace['POINTS']
            results.update(subrace)

        # sort by tiers, and then within tiers
        results_tier_sorted = results.sort_values('TIER')
        results_tier_sorted = results_tier_sorted.groupby('TIER', sort=False).apply(lambda x: x.sort_values(['BEST'])).reset_index(drop=True)

        results_tier_sorted.to_csv(savefolder+'/Results by Tier.csv', index_label='POS')

        # sort by teams, and then points within teams
        results_team_sorted = results.sort_values('TEAM')
        results_team_sorted = results_team_sorted.groupby('TEAM', sort=False).apply(lambda x: x.sort_values(['TIER'])).reset_index(drop=True)

        results_team_sorted.to_csv(savefolder+'/Results by Team.csv', index=False, columns=['TEAM', 'NAME', 'TIER', 'RUN1', 'RUN2', 'BEST', 'POINTS'])

        # Calculate total points for each team
        teams = results['TEAM'].unique().tolist()

        teampoints = pd.DataFrame(columns = ['NAME', 'POINTS'])
        teampoints['NAME'] = teams

        for index, team in enumerate(teams):
            total = results[results['TEAM'] == team].POINTS.sum()
            teampoints.loc[teampoints['NAME'] == team, 'POINTS'] = total

        teampoints = teampoints.sort_values('POINTS', ascending=False)
        teampoints = teampoints.reset_index(drop=True)
        teampoints.index += 1
        teampoints.to_csv(savefolder+'/Total Team Points.csv', index_label='POS')


app = Application()                       
app.master.title('Fun and Glory Calculator')    
app.mainloop()
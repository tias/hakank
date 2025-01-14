# Copyright 2021 Hakan Kjellerstrand hakank@gmail.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""

  Set covering problem in OR-tools CP-SAT Solver.

  This example is from the OPL example covering.mod
  '''
  Consider selecting workers to build a house. The construction of a
  house can be divided into a number of tasks, each requiring a number of
  skills (e.g., plumbing or masonry). A worker may or may not perform a
  task, depending on skills. In addition, each worker can be hired for a
  cost that also depends on his qualifications. The problem consists of
  selecting a set of workers to perform all the tasks, while minimizing the
  cost. This is known as a set-covering problem. The key idea in modeling
  a set-covering problem as an integer program is to associate a 0/1
  variable with each worker to represent whether the worker is hired.
  To make sure that all the tasks are performed, it is sufficient to
  choose at least one worker by task. This constraint can be expressed by a
  simple linear inequality.
  '''

  Solution from the OPL model (1-based)
  '''
  Optimal solution found with objective: 14
  crew= {23 25 26}
  '''

  Solution from this model (0-based):
  '''
  Total cost 14
  We should hire these workers:  22 24 25
  '''

  This is a port of my old OR-tools CP model covering_opl.py

  
  This model was created by Hakan Kjellerstrand (hakank@gmail.com)
  Also see my other OR-tools models: http://www.hakank.org/or_tools/
"""
from __future__ import print_function
from ortools.sat.python import cp_model as cp
import math, sys
from cp_sat_utils import scalar_product


def main():

  model = cp.CpModel()

  #
  # data
  #
  nb_workers = 32
  Workers = list(range(nb_workers))
  num_tasks = 15
  Tasks = list(range(num_tasks))

  # Which worker is qualified for each task.
  # Note: This is 1-based and will be made 0-base below.
  Qualified = [[1, 9, 19, 22, 25, 28, 31],
               [2, 12, 15, 19, 21, 23, 27, 29, 30, 31, 32],
               [3, 10, 19, 24, 26, 30, 32], [4, 21, 25, 28, 32],
               [5, 11, 16, 22, 23, 27, 31], [6, 20, 24, 26, 30, 32],
               [7, 12, 17, 25, 30, 31], [8, 17, 20, 22, 23],
               [9, 13, 14, 26, 29, 30, 31], [10, 21, 25, 31, 32],
               [14, 15, 18, 23, 24, 27, 30, 32], [18, 19, 22, 24, 26, 29, 31],
               [11, 20, 25, 28, 30, 32], [16, 19, 23, 31],
               [9, 18, 26, 28, 31, 32]]

  Cost = [
      1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5,
      5, 6, 6, 6, 7, 8, 9
  ]

  #
  # variables
  #
  Hire = [model.NewBoolVar("Hire[%i]" % w) for w in Workers]
  total_cost = model.NewIntVar(0, nb_workers * sum(Cost), "total_cost")

  #
  # constraints
  #
  scalar_product(model, Hire,Cost,total_cost)

  for j in Tasks:
    # Sum the cost for hiring the qualified workers
    # (also, make 0-base)
    model.Add(sum([Hire[c - 1] for c in Qualified[j]]) >= 1)

  # objective: Minimize total cost
  model.Minimize(total_cost)

  #
  # search and result
  #
  solver = cp.CpSolver()
  status = solver.Solve(model)
  
  if status == cp.OPTIMAL:
    print("Total cost", solver.Value(total_cost))
    print("We should hire these workers: ", end=" ")
    for w in Workers:
      if solver.Value(Hire[w]) == 1:
        print(w, end=" ")
    print()

  print()
  print("NumConflicts:", solver.NumConflicts())
  print("NumBranches:", solver.NumBranches())
  print("WallTime:", solver.WallTime())


if __name__ == "__main__":
  main()

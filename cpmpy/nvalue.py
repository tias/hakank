"""
Global constraint nvalue in cpmpy.

Clobal Constraint Catalog
http://www.emn.fr/x-info/sdemasse/gccat/Cnvalue.html
'''
Purpose 
   NVAL is the number of distinct values taken by the variables of the collection VARIABLES
Example
  (4,<3,1,7,1,6>)

The nvalue constraint holds since its first argument NVAL=4 is set to the number of distinct
values occurring within the collection <3,1,7,1,6>.
'''

Model created by Hakan Kjellerstrand, hakank@hakank.com
See also my cpmpy page: http://www.hakank.org/cpmpy/

"""
import sys
import numpy as np
from cpmpy import *
from cpmpy.solvers import *
from cpmpy_hakank import *


def print_solution(a):
    x = a[0]
    m = a[1][0]
    print("m:",m.value(), "x:",x.value())

def nvalue_test(n=5):
    x = intvar(1,n,shape=n,name="x")
    m = intvar(0,n,name="m" ) # number of distinct values

    # constraints
    model = Model(nvalue(m,x))

    # model += (m==n) # Force that all values are distinct.

    ortools_wrapper(model,[x,[m]],print_solution)

n = 5
nvalue_test(n)
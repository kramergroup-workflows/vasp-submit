import math

def norm(x):
  '''
  Compute the norm of an array x (i.e., the length of the vector represented 
  by that array)
  '''

  return math.sqrt(sum(i**2 for i in x))


def dot(v1, v2):
  '''
  Compute the inner product of two vectors represented by arrays
  '''

  return sum(x*y for x,y in zip(v1,v2))

def cross(a, b):
  '''
  Compute the cross product of two vectors represented by arrays
  '''

  c = [a[1]*b[2] - a[2]*b[1],
        a[2]*b[0] - a[0]*b[2],
        a[0]*b[1] - a[1]*b[0]]

  return c
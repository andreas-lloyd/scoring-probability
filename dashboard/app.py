import streamlit as st
import re
import pandas as pd
import plotnine as pn

MIN_SLIDER = 0.0
MAX_SLIDER = 10.0

def parse_function(function):
    # Get all letters that are not x
    variables = re.findall('([A-wy-z])', function)

    return variables

default_functions = [
    'a * x',
    'x**b',
    'Own function'
]

# Drop down input
option = st.selectbox(
    'What function do you want to transform the probabilities into scores?',
    default_functions
    )

# If own function then text input
if option == 'Own function':
    option = st.text_input('Enter own function where x is the inverse of probability and all other constants are variables')

# Parse option and look for variables
variables = parse_function(option)

# A slider to determine which constant value we want
variable_dic = {}
for variable in variables:
    variable_dic[variable] = st.slider(f'Choose a value for {variable}', MIN_SLIDER, MAX_SLIDER, 1.0, 0.5)

# NOW use pandas and plotnine and we can just .draw(); and st.pyplot() - for now use basic DF for probabilities
# We can use this for the function plot - and for distribution make an API call
st.write(variable_dic)
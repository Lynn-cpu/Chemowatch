#import the package;streamlit into the program and name it st
import streamlit as st
st.write("Session ID:", id(st.session_state))
#brings python's random-number tools into my program to pretend that the watch is producing different readings
import random

st.title("ChemoWatch")
st.write("A prototype for monitoring temperature and heart rate during chemotherapy")

#if i don't have a storage box called temperatures, create one and make it an empty list
if "temperatures" not in st.session_state:
    st.session_state.temperatures = []
#creating a temperature variable and uniform means python can choose a random decimal number between two numbers
#round rounds it to 1 decimal place
temperature = round(random.uniform(98.0, 102.0),1)
col1, col2 = st.columns(2)
#puts the temperature value inside of the 1st column
with col1:
    #Printing this on the webpage metric is a Streamlit function designed to display an important number on a dashboard
    st.metric("Temperature", temperature)

# randint means random interger (presents it as a whole number with no decimals
heart_rate=random.randint(60, 102)
with col2:
    st.metric("Heart Rate", heart_rate)

if st.button("Add temperature"):
    st.session_state.temperatures.append(temperature)
#st.session_state.temperatures.append(100)
st.write(st.session_state.temperatures)
st.subheader("Temperature Trend")
#line chart basically means take the numbers in the list and draw a line graph from them
st.line_chart(st.session_state.temperatures)
st.write("Number of readings:", len (st.session_state.temperatures))

if temperature >= 101:
    status = "Fever alert"
    #st.error("Fever alert")

else:
    status = "Normal"

#st.write basically puts this information on the webpage and st.error makes it an error message
st.write("Status:", status)

if status == "Fever alert":
    message = "The recorded temperature is above prototype normal"
else:
    message = "The recorded temperature is normal"
    
if status == "Fever alert":
    st.error (message)
else:
    st.info(message)
    
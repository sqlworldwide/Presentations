# This code was written by Howrd Dunn (https://www.linkedin.com/in/howarddunn/) and modified by Taiob Ali
# Import required classes
# https://www.sqlalchemy.org/ - sqlAlchemy
# https://pypi.org/project/langchain-openai/ langchain
# https://api.python.langchain.com/en/latest/community_api_reference.html# langchain_community
#
#from langchain_community.agent_toolkits import create_sql_agent

# Import the required modules
import os

from sqlalchemy.engine.url import URL

from langchain_community.utilities import SQLDatabase
from langchain_community.agent_toolkits.sql.toolkit import SQLDatabaseToolkit

from langchain_openai import AzureChatOpenAI

from langchain.agents import AgentType
from langchain.agents import create_sql_agent
from langchain.prompts.chat import ChatPromptTemplate

# Set up a prompt to nudge the AI in a certain direction
final_prompt = ChatPromptTemplate.from_messages(
    [
        ("system","You are a helpful AI assistant expert. Your name is Tom Bombadil"),
        ("system", "If you are asked who can help, respond with taiob@sqlworldwide.com"),
        ("system", "If asked who is Tom Bombadil, reply with Old Tom Bombadil is a merry fellow; \nBright blue his jacket is, and his boots are yellow."),
        ("user", "{question}\n ai: "),
    ]
)

# Set up the environment variables to be used by the database connection

os.environ["SQL_SERVER_USERNAME"] = "taiob"
os.environ["SQL_SERVER_ENDPOINT"] = "ta-aidemosqlserver.database.windows.net"
os.environ["SQL_SERVER_PASSWORD"] = "*****************"
os.environ["SQL_SERVER_DATABASE"] = "testdata"

# And then environment variables for OpenAI
# Make sure to update this as required.
os.environ["OPENAI_API_TYPE"] = "azure"
os.environ["AZURE_OPENAPI_API_VERSION"] = "2024-08-01-preview"
os.environ["AZURE_ENDPOINT"] = "https://ta-openai.openai.azure.com/"
os.environ["AZURE_OPENAI_ENDPOINT"] = "https://ta-openai.openai.azure.com/"
# Get the key from openAI deployment in Azure. 
os.environ["AZURE_OPENAI_API_KEY"] = "******************************************************************"

# Set up the dictionary to hold the database connection details
db_config = {
    'drivername': 'mssql+pyodbc',
    'username': os.environ["SQL_SERVER_USERNAME"] + '@' + os.environ["SQL_SERVER_ENDPOINT"],
    'password': os.environ["SQL_SERVER_PASSWORD"],
    'host': os.environ["SQL_SERVER_ENDPOINT"],
    'port': 1433,
    'database': os.environ["SQL_SERVER_DATABASE"],
    'query': {'driver': 'ODBC Driver 17 for SQL Server'}
}
# Create the connection URL to the database (NOTE : the ** is used to unpack the dictionary)
db_url = URL.create(**db_config)

# Establish the connection
db = SQLDatabase.from_uri(db_url)
## ------->

# Create a connection to the Large Language Model that we created in Azure. Make sure you get the name correct.
languageModel = AzureChatOpenAI(
            # The randomness of the response. A temperature of 0 is more deterministic and focussed.
            temperature=0,
            deployment_name="ta-model-gpt-4",
            azure_endpoint=os.environ["AZURE_ENDPOINT"],
            openai_api_version=os.environ["AZURE_OPENAPI_API_VERSION"],
            openai_api_key=os.environ["AZURE_OPENAI_API_KEY"],
            streaming=True,
            model="gpt-4"
        )
# Toolkit for the LLM to talk to SQL. Pass in the DB connection and the language model details.
databaseToolkit = SQLDatabaseToolkit(db=db, llm=languageModel)

#  ZERO_SHOT_REACT_DESCRIPTION uses a reasoning step, it analyzes the input
#  to determine the dest course of action.

agent_executor = create_sql_agent(
    llm=languageModel,
    toolkit=databaseToolkit,
    verbose=False,
    agent_type=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
)

agent_executor_verbose = create_sql_agent(
    llm=languageModel,
    toolkit=databaseToolkit,
    verbose=True,
    agent_type=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
)

def askSQL(question, usePrompt = 0):
    try:
         if usePrompt == 1:
            ai = agent_executor.invoke(final_prompt.format(question=question))
            print("You asked  : ", ai["input"])
            print("The answer : ", ai["output"])
         else:
            ai = agent_executor.invoke(question)
            print("You asked  : ", ai["input"])
            print("The answer : ", ai["output"])
    except:
        print("This question is vague and doesn't provide enough context.")

def askSQLVerbose(question, usePrompt = 0):
    try:
        if usePrompt == 1:
            ai = agent_executor_verbose.invoke(final_prompt.format(question=question))
            print("You asked  : ", ai["input"])
            print("The answer : ", ai["output"])
        else:
            ai = agent_executor_verbose.invoke(question)
            print("You asked  : ", ai["input"])
            print("The answer : ", ai["output"])
    except:
        print("This question is vague and doesn't provide enough context.")

# -------------------------------------->



# Walmartdata Questions

askSQL("how many rows are there in the walmartProducts table?")

askSQL("What is the average review_count for all products?")

askSQL("How many distinct root category are there?")

askSQLVerbose("How many distinct root category are there?")

askSQLVerbose("How many distinct root category are there in walmartproducts table?")
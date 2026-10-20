# LangChain vs LangGraph vs LangFlow vs LangSmith: Which One To Use & Why?

> **TL;DR:**
>
> - LangChain builds the app.
> - LangGraph orchestrates complex workflows.
> - LangFlow visualizes the design.
> - LangSmith monitors and improves the live system.
>    Together, they form a practical stack for modern AI application development.

---

## LangChain: Popular framework for building applications with LLMs

- **What:** An open-source framework for building applications powered by language models.
- **Why:** Simplifies managing complex logic, API calls, memory, and boilerplate code when chaining LLM interactions.
- **How:** Provides abstractions and classes (like memory, agents, and sequential chains) to connect prompts, external data, and models (like GPT-4 or Llama 3) into a cohesive workflow.

## LangGraph: Focuses on graph-based representations for AI workflows

- **What:** An open-source library built on LangChain to manage agents and their workflows.
- **Why:** Specifically designed for complex, structured, and cyclical multi-agent interactions that go beyond simple linear prompt chaining.
- **How:** Utilizes a graph-based structure consisting of State (shared data), Nodes (actions/tasks), and Edges (the execution flow).

## LangFlow: Visual programming interface for LangChain

- **What:** A visual, drag-and-drop interface built on top of LangChain.
- **Why:** Enables non-coders and teams to rapidly prototype and experiment with AI workflows, chains, and agents.
- **How:** By providing a UI where users connect components; workflows can be hosted locally or on cloud servers and accessed via APIs.

## LangSmith: Tool for managing and evaluating LLM prompts and outputs

- **What:** A platform for monitoring, testing, and debugging LLM applications throughout their lifecycle.
- **Why:** Ensures applications perform well in production by offering deep insights into latency, cost, token usage, and error rates.
- **How:** Can be connected to any LLM framework (not just LangChain) by adding environment variables and using the traceable annotation to log application performance to a dashboard.

---

## The problem with building it all from scratch

Imagine you want an application that:

- uses GPT-4 for the first response,
- uses Llama 3 to refine or improve that response,
- has an agent that decides whether to fetch external data or generate an answer,
- keeps memory of prior interactions with the user.

Without a framework, you end up writing a lot of custom logic by hand:

1. one function to call GPT-4,
2. another to call Llama 3,
3. custom code to manage memory,
4. custom code to update and retrieve conversation history,
5. custom agent logic to decide what to do next,
6. custom orchestration between all those steps.

### EXAMPLE 1 - no framework: raw Python

```python
# example_1_no_framework.py
#
# Install:
#   uv init
#   uv add openai requests
#   uv run python example_1_no_framework.py

import openai
import requests

memory = {}

# 1. direct model call to GPT-4

def query_gpt4(prompt: str) -> str:
    openai.api_key = "your-gpt4-api-key"
    response = openai.Completion.create(
        engine="gpt-4",
        prompt=prompt,
        max_tokens=120,
    )
    return response.choices[0].text.strip()

# 2. direct model call to Llama 3

def query_llama3(prompt: str) -> str:
    url = "https://llama3-api-endpoint"
    headers = {
        "Authorization": "Bearer your-llama3-api-key",
        "Content-Type": "application/json",
    }
    payload = {
        "prompt": prompt,
        "max_tokens": 120,
    }
    response = requests.post(url, headers=headers, json=payload, timeout=30)
    response.raise_for_status()
    return response.json()["response"].strip()

# 3. custom memory layer

def update_memory(user_input: str, response: str) -> None:
    memory["last_interaction"] = {"input": user_input, "response": response}


def get_memory() -> dict:
    return memory.get("last_interaction", {})

# 4. custom agent logic: choose the model based on the query

def agent(query: str) -> str:
    last_interaction = get_memory()

    # simple decision rule: "complex" questions go to GPT-4
    if "complex" in query.lower():
        response = query_gpt4(query)
    else:
        response = query_llama3(query)

    update_memory(query, response)
    return response


if __name__ == "__main__":
    question = "Explain the difference between GPT-4 and Llama 3 in a few sentences."
    result = agent(question)
    print(result)
```

That approach is workable for a small prototype, but it quickly becomes fragile.

There is a lot of boilerplate code, a lot of API handling, and a lot of custom logic for decision-making.

As the application grows in complexity, the code becomes harder to maintain and scale.

---

## LangChain: building apps with LLMs

LangChain is an open-source framework for building applications powered by language models.

**Key features:**

- **Abstractions:** Pre-built steps and concepts that you can chain together
- **LLM Support:** support for many providers and models
- **Prompt:** reusable templates for generating prompts
- **Chains:** sequences of tasks connected together
- **Indexes:** document indexing (document loading) and retrieval
- **Memory:** to maintain context and past interactions
- **Agents:** use llm as reasoning engines to decide the next workflow step

### EXAMPLE 2 - same logic as example 1, but with LangChain

```python
# example_2_langchain.py
#
# Install:
#   uv init
#   uv add langchain langchain-openai langchain-community
#   uv run python example_2_langchain.py

from langchain.prompts import PromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain.memory import ConversationBufferMemory
from langchain_openai import ChatOpenAI
from langchain_community.llms import LlamaCpp

# 1. define the two model providers

gpt4_llm = ChatOpenAI(model="gpt-4", temperature=0)
llama3_llm = LlamaCpp(model_path="/path/to/llama3-model.gguf")

# 2. build reusable prompts
prompt_template = PromptTemplate(
    input_variables=["query", "history"],
    template="""You are a helpful assistant.

History:
{history}

User question:
{query}
""",
)

memory = ConversationBufferMemory(return_messages=True)

# 3. same routing logic as the no-framework version, but encapsulated

def answer_query(query: str) -> str:
    history = memory.buffer

    if "complex" in query.lower():
        llm = gpt4_llm
    else:
        llm = llama3_llm

    chain = prompt_template | llm | StrOutputParser()
    answer = chain.invoke({"query": query, "history": history})

    memory.chat_memory.add_user_message(query)
    memory.chat_memory.add_ai_message(answer)
    return answer


if __name__ == "__main__":
    print(answer_query("Explain why LLM agents need memory."))
    print("---")
    print(answer_query("This is a very complex question about how to build a research agent."))
```

In other words, LangChain is the application framework layer.
It helps structure the system without forcing you to reinvent the plumbing of each model call and each intermediate step.

---

## LangGraph: managing complex workflow orchestration

LangGraph is built on top of LangChain and is focused on graph-based multi-agent workflows.

While LangChain is great for prompt chaining, LangGraph excels at handling multiple agents in more structured workflows.

If you're building a system where multiple agents interact to solve complex problems, such as task automation, research assistance, or decision loops, you can consider using LangGraph.

LangGraph has a concept of graph with 3 core components:

1. state:

- a shared data structure that represents the current snapshot of the application
- it maintains information that can be updated and accessed by different parts of the graph
- a typical state might include user inputs, agent outcomes, and a list of actions taken throughout the workflow

2. nodes:

- represent the individual components or actions within the graph
- each node can perform a specific task, such as executing an LLM, running a function, or interacting with external tools

3. edges:

- connect nodes and define the flow of execution within the graph
- they determine how data moves from one node to another

This makes it especially useful when the system has multiple steps, conditional paths, loops, or interactions between agents. A simple chain is not enough once your app starts behaving more like a dynamic state machine.

### Why it is useful

If you are building a system where multiple agents collaborate, where a task may revisit a node after new information arrives, or where complex routing decisions matter, LangGraph gives you the structure to model that more explicitly.

### EXAMPLE 3 - same logic as example 1, but with LangGraph

```python
# example_3_langgraph.py
#
# Install:
#   uv init
#   uv add langgraph langchain-openai langchain-community
#   uv run python example_3_langgraph.py

from typing import TypedDict, Annotated, List
from langgraph.graph import StateGraph, END
from langchain_openai import ChatOpenAI
from langchain_community.llms import LlamaCpp

# 1. state holds the current query, memory, and output

class State(TypedDict):
    query: str
    history: List[str]
    answer: str

# 2. model definitions

gpt4_llm = ChatOpenAI(model="gpt-4", temperature=0)
llama3_llm = LlamaCpp(model_path="/path/to/llama3-model.gguf")

# 3. route the request by complexity

def choose_model(state: State):
    if "complex" in state["query"].lower():
        return {"query": state["query"], "history": state["history"], "answer": "gpt4"}
    return {"query": state["query"], "history": state["history"], "answer": "llama3"}

# 4. execute GPT-4 path

def run_gpt4(state: State):
    answer = gpt4_llm.invoke(state["query"]).content
    return {"query": state["query"], "history": state["history"] + [answer], "answer": answer}

# 5. execute Llama 3 path

def run_llama3(state: State):
    answer = llama3_llm.invoke(state["query"])
    return {"query": state["query"], "history": state["history"] + [answer], "answer": answer}

# 6. graph wiring

workflow = StateGraph(State)
workflow.add_node("choose_model", choose_model)
workflow.add_node("gpt4", run_gpt4)
workflow.add_node("llama3", run_llama3)
workflow.add_edge("choose_model", "gpt4")
workflow.add_edge("choose_model", "llama3")
workflow.set_entry_point("choose_model")
workflow.add_conditional_edges(
    "choose_model",
    lambda state: "gpt4" if state["answer"] == "gpt4" else "llama3",
    {"gpt4": "gpt4", "llama3": "llama3"},
)
workflow.add_edge("gpt4", END)
workflow.add_edge("llama3", END)

app = workflow.compile()

# 7. example usage

result = app.invoke({"query": "This is a very complex question about planning a research workflow.", "history": [], "answer": ""})
print(result["answer"])
```

---

## LangFlow: visual programming for LangChain workflows

LangFlow is a visual interface for building workflows on top of LangChain.

Rather than writing many lines of code, you can connect components in a drag-and-drop interface. This makes experimentation faster and helps teams prototype ideas quickly.

### Why it helps

LangFlow is especially useful for:

- prototyping AI systems visually,
- letting non-coders understand the flow,
- experimenting with chains and agents without deep implementation overhead,
- hosting or exposing workflows through APIs.

It is not a replacement for the core programming model; it is a visual layer that makes building and testing those models easier.

### EXAMPLE 4 - same logic as example 1, but in LangFlow

```python
# example_4_langflow.py
#
# Install:
#   uv init
#   uv add langflow
#   uv run langflow run --host 0.0.0.0 --port 7860
#
# Then open the browser at http://localhost:7860
# and build a flow with:
#   - Prompt input
#   - LLM node (GPT-4 or Llama 3)
#   - Router / condition node
#   - Memory node
#   - Output node

# In practice, the flow looks like this:
#
# User input --> Router --> GPT-4 node
#            \--> Llama 3 node --> Output
#
# You can also call the web app from another service:

import requests

FLOW_URL = "http://localhost:7860/api/v1/run"

def call_langflow(question: str):
    payload = {
        "input": {"question": question},
        "stream": False,
    }
    response = requests.post(FLOW_URL, json=payload, timeout=60)
    response.raise_for_status()
    return response.json()


if __name__ == "__main__":
    result = call_langflow("This is a very complex research question.")
    print(result)
```

```sh
# Optional: if you want to run LangFlow from the terminal
# uv run langflow run --host 0.0.0.0 --port 7860
# then open http://localhost:7860
```

---

## LangSmith: monitoring and improving production AI systems

LangSmith is for monitoring, testing, and debugging LLM applications across their lifecycle.

This is where production concerns come in: latency, cost, token usage, errors, and application performance.

### Why it matters

In real AI systems, it is not enough to get a result once. You need to know:

- how long requests take,
- how expensive they are,
- which prompts produce the wrong behavior,
- where failures occur,
- how to improve prompt quality and reliability over time.

LangSmith gives you the observability needed to support that.

### EXAMPLE 5 - same logic as example 1, but with LangSmith tracing

```python
# example_5_langsmith.py
#
# Install:
#   uv init
#   uv add openai langsmith
#   uv run python example_5_langsmith.py

import openai
from langsmith import traceable
from langsmith.wrappers import wrap_openai

# 1. wrap the OpenAI client so LangSmith can observe every call
client = wrap_openai(openai.Client(api_key="your-openai-api-key"))

# 2. the same business logic: choose the model based on the query
@traceable
def answer_query(query: str) -> str:
    if "complex" in query.lower():
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": query}],
        )
        return response.choices[0].message.content

    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": query}],
    )
    return response.choices[0].message.content


if __name__ == "__main__":
    result = answer_query("This is a very complex question about building a research assistant.")
    print(result)
```

By using the `traceable` annotation, LangSmith will receive all of these traces.

In the LangSmith dashboard, you'll be able to see all the details on:

- how many tokens were used
- how many calls were made
- the total cost, error rate, and latency details;

You can also monitor trends of:

- the number of calls
- the number of tokens
- the latencies etc.

---

## The key takeaway

The pattern is the same across all examples: the application decides which model to use, manages temporary state, and coordinates a multi-step workflow.

The difference is not the core idea itself. The difference is how much structure, observability, and reuse the framework adds to the system.

- No framework: everything is manual and tightly coupled.
- LangChain: better abstractions and reusable workflow building blocks.
- LangGraph: explicit orchestration for multi-step and multi-agent architectures.
- LangFlow: visual design and rapid prototyping.
- LangSmith: debugging, monitoring, and production visibility.
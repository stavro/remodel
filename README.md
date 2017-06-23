# Remodel #

[![Build Status](https://semaphoreci.com/api/v1/projects/8c5cf51e-a3e8-47a6-8b91-632114de4fba/480819/badge.svg)](https://semaphoreci.com/stavro/remodel)

Remodel is an Elixir _presenter_ package used to transform data structures.  This is especially useful when a desired representation doesn't match the schema defined within the database.

In particular, Remodel enables:

 * Renaming or aliasing attributes to change the name from the model
 * Arbitrary attributes based on combining data in an object
 * Inclusion of attributes only if a certain conditions have been met
 * Addition of root nodes on arrays or instances
 * Easy conversion to a list representation (eg, for CSVs)

## Installation ##

Install Remodel as a hex dependency in your `.mix` file:

```elixir
  defp deps do
    [{:remodel, "~> 0.0.4"}]
  end
```

and run `mix deps.get` to install the package.

## Overview ##

You can use Remodel to prepare an Elixir Map (or anything that identifies as a Map, such as a Struct or an Ecto.Model instance) to be serialized through a JSON, XML, or CSV serializer.

With Remodel, the data is derived from maps (ORM-agnostic) and the representation of the API output is described by attributes and methods using a simple Elixir DSL. This allows you to keep your data separated from the structure you wish to output.

Once you have installed Remodel (explained above), you can construct a Remodel schema and then render the model
from your Plug or Phoenix applications from the controller (or route) very easily. Using [Phoenix](http://phoenixframework.org) and [Ecto](https://github.com/elixir-lang/ecto) as an example, assuming you have a `Post` model filled with blog posts, you can render an API representation by creating a route:

```elixir
# web/controllers/post_controller.ex
def index(conn, params) do
  posts = Repo.all(from p in Post,
                   select: p,
                   order_by: [asc: p.id],
                   preload: :author)

  json(conn, PostSerializer.to_map(posts))
end
```

Then we can create the following Remodel schema to express the desired API output of `posts`:

```elixir
# web/serializers/post_serializer.ex
defmodule PostSerializer do
  use Remodel

  attributes [:id, :title, :author_name]

  def author_name(record) do
    "#{record.author.first_name} #{record.author.last_name}"
  end
end
```

Which would output the following JSON when visiting the appropriate action:

```js
[
  {
    "id" : 1,
    "title": "Introducing Remodel",
    "author_name" : "Sean Stavropoulos"
  },
  {
    "id" : 2,
    ...
  }
]
```

### Attributes ###

Basic usage to define a few simple attributes for the response:

```elixir
attributes [:id, :foo, :bar]
```

or use with aliased attributes:

```elixir
# Take the value of model attribute `foo` and name the node `bar`
attribute :foo, as: :bar
# => %{bar: 5}
```

or show attributes only if a condition is true:

```elixir
# atom representing a method in the serializer
attribute :foo, if: :published

def published(record) do
  !is_nil(record.published_at)
end
```

### Root Nodes ###

Some JSON configurations will include a single root node named after the object's type or an abstractable name for the object depending on context.  Remodel can accomodate these JSON types on an individual, or a default basis.

Example usage of root nodes:

```elixir
defmodule UserSerializer do
  use Remodel
  @array_root :users

  attribute :id
end

[%{id: 1}, %{id: 2}] |> UserSerializer.to_map #=>  %{users: [%{id: 1}, %{id: 2}]}
[%{id: 1}, %{id: 2}] |> UserSerializer.to_map(array_root: :superusers) #=>  %{superusers: [%{id: 1}, %{id: 2}]}
```

Example usage of instance root nodes:

```elixir
defmodule UserSerializer do
  use Remodel
  @instance_root :user

  attribute :id
end

[%{id: 1}, %{id: 2}] |> UserSerializer.to_map #=>  %{[%{user: %{id: 1}}, %{user: %{id: 2}}]}
[%{id: 1}, %{id: 2}] |> UserSerializer.to_map(instance_root: :user) #=>  %{[%{user: %{id: 1}}, %{user: %{id: 2}}]}
```

### List Generation ###

Remodel includes two formatters to transform map structures.  The first, as visible in the above examples, converts an input map to an output map.  Remodel also includes a transformation useful for working with list-based tools, such as most CSV generators.

```elixir
defmodule UserSerializer do
  use Remodel
  attributes [:id, :full_name]

  def full_name(record) do
    "#{record.first_name} #{record.last_name}"
  end
end

# Save all users from the database to a CSV
Repo.all(from u in User, select: %{id: u.id, first_name: u.first_name, last_name: u.last_name})
|> UserSerializer.to_list(headers: true)  # => [[:id, :full_name], [1, "Joe Armstrong"], ...]
|> CSVLixir.write
|> File.write("foo.csv")
:ok
```

### Scope ###

Some serialization configurations may depend on data outside of the serialized resource (for example, utilizing information about the currently authenticated user).  Remodel allows passing in any scope data type which can be referenced throughout the serialization process.

Here's an example to only display a particular attribute if a user is requesting their own serialized user object:

```elixir
defmodule UserSerializer do
  use Remodel

  attribute :id
  attribute :email, if: :personal_info_visible?

  def personal_info_visible?(record, scope) do
    scope.id == record.id
  end
end

# Assume a current_user variable has been set to the authenticated user
current_user = Repo.get(User, 1)

Repo.one(from u in User, where: u.id == 1, select: u, limit: 1) |> UserSerializer.to_map(scope: current_user)
#=> %{id: 1, email: "email@domain.com"}

Repo.one(from u in User, where: u.id == 2, select: u, limit: 1) |> UserSerializer.to_map(scope: current_user)
#=> %{id: 2}
```

All attribute and conditional functions must accept either one argument (the record), or two arguments (the record, and any given scope)
### Meta ###

Often when you have pagination with your data you use a meta field for showing additional information (current_page, total_pages, etc).
`meta` will only be included if you have a Serializer that supports `root`

```elixir
defmodule UserSerializer do
  use Remodel
  @array_root :users

  attribute :id
end

[%{id: 1}, %{id: 2}] |> UserSerializer.to_map(meta: %{ page: 1 } #=>  %{users: [%{id: 1}, %{id: 2}], "meta" => %{ page: 1}}
```
## Roadmap ##

Remodel is a brand new project, and I am hopeful that there is a place in the Elixir ecosystem for such a tool.  In no particular order of importance, some features I would like to add are:

 * Typespecs and Documentation
 * DRY up test suite
 * Anonymous functions for `if` clauses: (eg: `attribute :foo, if: fn(record) -> record.bar end`)
 * Benchmarking and performance optimizations
 * Handling of Ecto Associations

## Inspirations ##

There are a few excellent libraries that helped inspire Remodel and they are listed below:

 * [Active Model Serializers](https://github.com/rails-api/active_model_serializers)
 * [RABL](https://github.com/nesquena/rabl)

## License

Copyright 2015 Sean Stavropoulos

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

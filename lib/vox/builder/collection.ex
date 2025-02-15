defmodule Vox.Builder.Collection do
  use GenServer

  @initial_state %{
    collections: MapSet.new(),
    files: []
  }

  # ┌────────────┐
  # │ Client API │
  # └────────────┘

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: __MODULE__])
  end

  def add(collectable, :unprocessed) do
    GenServer.call(__MODULE__, {:add, {collectable, :unprocessed}})
  end

  def add_collections(collections) do
    GenServer.cast(__MODULE__, {:add_collections, collections})
  end

  def list_files() do
    GenServer.call(__MODULE__, :list_files)
  end

  def update_files(files) do
    GenServer.call(__MODULE__, {:update_files, files})
  end

  def assigns do
    GenServer.call(__MODULE__, :assigns)
  end

  def empty do
    GenServer.call(__MODULE__, :empty)
  end

  def inspect() do
    GenServer.call(__MODULE__, :inspect)
  end

  # ┌──────────────────┐
  # │ Server Callbacks │
  # └──────────────────┘

  def init(_) do
    {:ok, @initial_state}
  end

  def handle_call({:add, {path, :unprocessed}}, _, state) do
    state = Map.put(state, :files, [%Vox.Builder.File{source_path: path} | state.files])
    {:reply, state, state}
  end

  def handle_call(:list_files, _, state) do
    {:reply, state.files, state}
  end

  # TODO I could probably do this more efficiently by going through each file instead
  def handle_call(:assigns, _, state) do
    assigns =
      state.collections
      |> Enum.reduce(%{}, fn collection, acc ->
        files_in_collection =
          state.files
          |> Enum.filter(fn %{collections: collections} -> collection in collections end)

        Map.put(acc, collection, files_in_collection)
      end)
      |> Enum.into([])

    {:reply, assigns, state}
  end

  def handle_call(:inspect, _, state) do
    {:reply, state, state}
  end

  def handle_call(:empty, _, state) do
    {:reply, state, @initial_state}
  end

  def handle_call({:update_files, files}, _, state) do
    new_state = Map.put(state, :files, files)
    {:reply, new_state, new_state}
  end

  def handle_cast({:add, {file, type}}, state) do
    state = Map.update(state, type, [], &[file | &1])
    {:noreply, state}
  end

  def handle_cast({:add_collections, collections}, state) do
    collections_for_state =
      collections
      |> Enum.reduce(state.collections, fn collection, acc ->
        MapSet.put(acc, collection)
      end)

    {:noreply, %{state | collections: collections_for_state}}
  end
end

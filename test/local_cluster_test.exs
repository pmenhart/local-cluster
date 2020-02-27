defmodule LocalClusterTest do
  use ExUnit.Case
  doctest LocalCluster

  test "creates and stops child nodes" do
    nodes = LocalCluster.start_nodes(:child, 3)

    [node1, node2, node3] = nodes

    assert Node.ping(node1) == :pong
    assert Node.ping(node2) == :pong
    assert Node.ping(node3) == :pong

    :ok = LocalCluster.stop_nodes([node1])

    assert Node.ping(node1) == :pang
    assert Node.ping(node2) == :pong
    assert Node.ping(node3) == :pong

    :ok = LocalCluster.stop_nodes([node2, node3])

    assert Node.ping(node1) == :pang
    assert Node.ping(node2) == :pang
    assert Node.ping(node3) == :pang
  end

  test "spawns tasks directly on child nodes" do
    nodes = LocalCluster.start_nodes(:spawn, 3, [
      files: [
        __ENV__.file
      ]
    ])

    [node1, node2, node3] = nodes

    assert Node.ping(node1) == :pong
    assert Node.ping(node2) == :pong
    assert Node.ping(node3) == :pong

    caller = self()

    Node.spawn(node1, fn ->
      send(caller, :from_node_1)
    end)

    Node.spawn(node2, fn ->
      send(caller, :from_node_2)
    end)

    Node.spawn(node3, fn ->
      send(caller, :from_node_3)
    end)

    assert_receive :from_node_1
    assert_receive :from_node_2
    assert_receive :from_node_3

    :ok = LocalCluster.stop_nodes(nodes)
  end

  test "creates many child nodes" do
    nodes = LocalCluster.start_nodes(:child, 10)
    assert length(nodes) == 10
    for node <- nodes do
      assert Node.ping(node) == :pong
    end
    :ok = LocalCluster.stop_nodes(nodes)
    for node <- nodes do
      assert Node.ping(node) == :pang
    end
  end
end
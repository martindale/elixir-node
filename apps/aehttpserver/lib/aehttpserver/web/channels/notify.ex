defmodule Aehttpserver.Web.Notify do
  alias Aecore.Structures.SpendTx
  alias Aecore.Structures.OracleQueryTxData
  alias Aeutil.Serialization
  alias Aecore.Structures.Account

  def broadcast_new_transaction_in_the_pool(tx) do
    broadcast_tx(tx, true)

    broadcast_tx(tx, false)

    Aehttpserver.Web.Endpoint.broadcast!("room:notifications", "new_transaction_in_the_pool", %{
      "body" => Serialization.tx(tx, :serialize)
    })
  end

  def broadcast_new_block_added_to_chain_and_new_mined_tx(block) do
    Enum.each(block.txs, fn tx ->
      Aehttpserver.Web.Endpoint.broadcast!("room:notifications", "new_mined_tx_everyone", %{
        "body" => Serialization.tx(tx, :serialize)
      })

      broadcast_tx(tx, true)
    end)

    Aehttpserver.Web.Endpoint.broadcast!("room:notifications", "new_block_added_to_chain", %{
      "body" => Serialization.block(block, :serialize)
    })
  end

  def broadcast_tx(tx, is_to_sender) do
    if is_to_sender do
      if tx.data.sender != nil do
        Aehttpserver.Web.Endpoint.broadcast!(
          "room:notifications",
          "new_tx:" <> Account.base58c_encode(tx.data.sender),
          %{"body" => Serialization.tx(tx, :serialize)}
        )
      end
    else
      case tx.data.payload do
        %SpendTx{} ->
          Aehttpserver.Web.Endpoint.broadcast!(
            "room:notifications",
            "new_tx:" <> Account.base58c_encode(tx.data.payload.receiver),
            %{"body" => Serialization.tx(tx, :serialize)}
          )

        %OracleQueryTxData{} ->
          Aehttpserver.Web.Endpoint.broadcast!(
            "room:notifications",
            "new_tx:" <> Account.base58c_encode(tx.data.payload.oracle_address),
            %{"body" => Serialization.tx(tx, :serialize)}
          )

        _ ->
          :ok
      end
    end
  end
end

defmodule StripeSpike.Router do
  use Plug.Router

  plug(:match)
  plug(Plug.Parsers, parsers: [:urlencoded], pass: ["text/*"])
  plug(:dispatch)

  @template_dir "lib/stripe_spike/views"

  get "/" do
    render(conn, "index.html")
  end

  get "/create_customer" do
    render(conn, "create_customer.html")
  end

  post "/new_customer" do
    name = conn.body_params["name"]

    address = %{
      line1: conn.body_params["street_address"],
      city: conn.body_params["city"],
      state: conn.body_params["state"],
      postal_code: conn.body_params["zip_code"],
      country: conn.body_params["country"]
    }

    customer_id = StripeSpike.create_customer(name, address)

    render(conn, "new_customer.html", customer_id: customer_id)
  end

  post "/create_invoice" do
    customer_id = conn.body_params["customer_id"]
    invoice_url = "localhost:4001/invoice/#{StripeSpike.create_invoice(customer_id)}"

    conn
    |> put_status(201)
    |> render("new_invoice.html", invoice_url: invoice_url)
  end

  # get "/invoice/:invoice_id" do
  #   invoice = StripeSpike.get_invoice(invoice_id)

  #   Map.keys(invoice)
  #   |> Enum.map(fn key -> "<br>#{key}: {#{map_crap(invoice[key])}}" end)
  #   |> Enum.join(",<br>")

  #   render(conn, "invoice.html", invoice: invoice)
  # end

  match _ do
    send_resp(conn, 404, "404: not found")
  end

  defp render(%{status: status} = conn, template, assigns \\ []) do
    body =
      @template_dir
      |> Path.join(template)
      |> String.replace_suffix(".html", ".html.eex")
      |> EEx.eval_file(assigns)

    send_resp(conn, status || 200, body)
  end

  defp map_crap(map) do
    Map.keys(map)
    |> Enum.map(fn key -> "#{key}: #{map[key]}" end)
    |> Enum.join(", ")
  end
end

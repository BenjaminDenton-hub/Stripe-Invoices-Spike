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
    customer_id = StripeSpike.create_customer(name)

    render(conn, "new_customer.html", customer_id: customer_id)
  end

  post "/create_invoice" do
    customer_id = conn.body_params["customer_id"]
    invoice_url = "localhost:4001/invoice/#{StripeSpike.create_invoice(customer_id)}"

    conn
    |> put_status(201)
    |> render("new_invoice.html", invoice_url: invoice_url)
  end

  get "/invoice/:invoice_id" do
    invoice = StripeSpike.get_invoice(invoice_id)

    render(conn, "invoice.html", invoice: invoice)
  end

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
end

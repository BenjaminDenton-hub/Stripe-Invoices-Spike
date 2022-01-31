defmodule StripeSpike do
  def create_customer(name, address) do
    {:ok, stripe_customer} =
      %{
        name: name,
        email: "bdenton@heroku.com",
        address: address
      }
      |> Stripe.Customer.create()

    {:ok, source} =
      %{
        :type => "card",
        :card => %{
          skip_validation: true,
          number: "4242424242424242",
          exp_month: 11,
          exp_year: 2030
        }
      }
      |> Stripe.Source.create()

    {:ok, payment_method} =
      Stripe.Card.create(%{
        :customer => stripe_customer.id,
        :source => source.id
      })

    {:ok, _result} =
      Stripe.PaymentMethod.attach(%{customer: stripe_customer.id, payment_method: payment_method})

    stripe_customer.id
  end

  def create_invoice(customer_id) do
    {:ok, stripe_customer} = Stripe.Customer.retrieve(customer_id)

    {:ok, invoice_lines} =
      %{
        amount: 40,
        customer: stripe_customer.id,
        currency: "usd",
        discountable: false
      } |> Stripe.Invoiceitem.create()

    upcase_country =
      stripe_customer.address[:country]
      |> String.upcase()

    if(upcase_country == "INDIA") do
      {:ok, invoice} =
        %{
          :collection_method => "send_invoice",
          :customer => stripe_customer.id,
          :days_until_due => 1
        }
        |> Stripe.Invoice.create()

      invoice.id
    else
      {:ok, invoice} =
        %{
          :collection_method => "charge_automatically",
          :customer => stripe_customer.id
        }
        |> Stripe.Invoice.create()

      invoice.id
    end
  end

  # def get_invoice(invoice_id) do
  #   {:ok, invoice} = Stripe.Invoice.retrieve(invoice_id)
  #   invoice
  # end
end

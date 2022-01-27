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
          number: "0000000000000000",
          exp_month: 11,
          exp_year: 2030
        }
      }
      |> Stripe.Source.create()

    {:ok, payment_method} =
      Stripe.Card.create(%{
        :customer => stripe_customer,
        :source => source
      })

    {:ok, _result} =
      Stripe.PaymentMethod.attach(%{customer: stripe_customer.id, payment_method: payment_method})

    stripe_customer.id
  end

  def create_invoice(customer_id) do
    {:ok, stripe_customer} = Stripe.Customer.retrieve(customer_id)
    upcase_country = String.upcase(stripe_customer.address[:country])

    if(upcase_country == "INDIA") do
      {:ok, invoice} =
        Stripe.Invoice.create(%{
          :collection_method => "send_invoice",
          :customer => stripe_customer,
          :days_until_due => 1
        })

      invoice.id
    else
      {:ok, invoice} =
        Stripe.Invoice.create(%{
          :collection_method => "charge_automatically",
          :customer => stripe_customer
        })

      invoice.id
    end
  end

  def get_invoice(invoice_id) do
    {:ok, invoice} = Stripe.Invoice.retrieve(invoice_id)
    invoice
  end
end

module FatFreeCRM
  module Highrise
    class Import

      #------------------------------------------------------------------------------
      def self.people(people)
        people.each { |p| import_person(p) }
      end

      #------------------------------------------------------------------------------
      def self.companies(companies)
        companies.each { |c| import_company(c) }
      end


      private
      #------------------------------------------------------------------------------
      def self.import_person(person)
        contact = Contact.create(
          :first_name => person.first_name[0..64],
          :last_name  => person.last_name[0..64],
          :title      => person.title[0..64],
          :access     => "Public",
          :email      => extract(person.contact_data, :work_email),
          :alt_email  => extract(person.contact_data, :home_email),
          :phone      => extract(person.contact_data, :work_phone),
          :mobile     => extract(person.contact_data, :mobile_phone),
          :fax        => extract(person.contact_data, :fax_phone),
          :blog       => extract(person.contact_data, :blog),
          :linkedin   => extract(person.contact_data, :linkedin),
          :facebook   => extract(person.contact_data, :facebook),
          :twitter    => extract(person.contact_data, :twitter),
          :address    => extract(person.contact_data, :address),
          :created_at => person.created_at
        )
        if person.company
          account = self.import_company(person.company)
          AccountContact.create(:account => account, :contact => contact)
        end
        puts contact.inspect
        # puts contact.account.inspect
        contact
      end

      #------------------------------------------------------------------------------
      def self.import_company(company)
        account = Account.find_by_name(company.name[0..64]) ||
        Account.create(
          :name             => company.name[0..64],
          :access           => "Public",
          :website          => extract(company.contact_data, :website),
          :toll_free_phone  => extract(company.contact_data, :tall_free_phone),
          :phone            => extract(company.contact_data, :work_phone),
          :fax              => extract(company.contact_data, :fax_phone),
          :billing_address  => extract(company.contact_data, :address),
          :shipping_address => extract(company.contact_data, :address)
        )
        puts account.inspect
        account
      end

      private
      #------------------------------------------------------------------------------
      def self.extract(contact_data, field)
        location = field.to_s.split("_").first.capitalize
        case field
        when :home_email, :work_email
          email = contact_data.email_addresses.detect { |addr| addr.location == location }
          email.address if email
        when :work_phone, :mobile_phone, :fax_phone
          phone = contact_data.phone_numbers.detect { |number| number.location == location }
          phone.number if phone
        when :tall_free_phone
          phone = contact_data.phone_numbers.detect { |number| number.number =~ /^\s*.{0,2}(800|888)[^\d]+/ }
          phone.number if phone
        when :website
          website = contact_data.web_addresses.detect { |site| site.location =~ /work|other/i }
          website.url if website
        when :blog
          website = contact_data.web_addresses.detect { |site| site.location =~ /personal|other/i }
          website.url if website
        when :linkedin
          website = contact_data.web_addresses.detect { |site| site.url =~ /linkedin/i }
          website.url if website
        when :facebook
          website = contact_data.web_addresses.detect { |site| site.url =~ /facebook/i }
          website.url if website
        when :twitter
          unless contact_data.twitter_accounts.blank?
            "http://twitter.com/#{contact_data.twitter_accounts.first.username}"
          end
        when :address
          unless contact_data.addresses.blank?
            addr = contact_data.addresses.first
            "#{addr.street}\n#{addr.city}, #{addr.state} #{addr.zip}\n#{addr.country}".strip
          end
        end
      end
    end
  end
end
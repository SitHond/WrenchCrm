return if Family.exists?

I18n.with_locale(:ru) do
  ActiveRecord::Base.transaction do
    ivanovs = Family.create!(name: "Ивановы", city: "Москва", address1: "ул. Ленина, 10, кв. 5", zip: "101000",
                             country: "Россия", home_phone: "+7 495 123-45-67", wedding_date: Date.new(2005, 6, 18))
    ivanovs.people.create!(first_name: "Сергей", middle_name: "Петрович", last_name: "Иванов", gender: :male,
                           family_role: :head_of_household, classification: :member, birth_day: 12, birth_month: Date.current.month,
                           birth_year: 1978, cell_phone: "+7 916 111-22-33", email: "sergey@example.com", membership_date: Date.new(2010, 4, 4))
    ivanovs.people.create!(first_name: "Анна", middle_name: "Викторовна", last_name: "Иванова", gender: :female,
                           family_role: :spouse, classification: :member, birth_day: 3, birth_month: 9, birth_year: 1981,
                           cell_phone: "+7 916 444-55-66", email: "anna@example.com", membership_date: Date.new(2010, 4, 4))
    ivanovs.people.create!(first_name: "Миша", last_name: "Иванов", gender: :male, family_role: :child,
                           classification: :regular_attender, birth_day: 21, birth_month: Date.current.month, birth_year: 2012)

    smiths = Family.create!(name: "Петровы", city: "Санкт-Петербург", address1: "Невский пр., 100", country: "Россия")
    smiths.people.create!(first_name: "Ольга", last_name: "Петрова", gender: :female, family_role: :head_of_household,
                          classification: :regular_attender, birth_day: 30, birth_month: 1, cell_phone: "+7 921 777-88-99")

    guest = Person.create!(first_name: "Дмитрий", last_name: "Соколов", gender: :male, classification: :guest,
                           friend_date: 2.weeks.ago.to_date, telegram: "@dsokolov")

    worship = Group.create!(name: "Прославление", group_type: :team, description: "Музыкальная команда воскресного служения.")
    youth = Group.create!(name: "Молодёжь", group_type: :ministry)
    Group.create!(name: "Домашняя группа на Таганке", group_type: :bible_study)

    leader = worship.group_roles.find_by!(default: false)
    worship.group_memberships.create!(person: ivanovs.people.find_by!(first_name: "Анна"), group_role: leader)
    worship.group_memberships.create!(person: ivanovs.people.find_by!(first_name: "Сергей"))
    youth.group_memberships.create!(person: ivanovs.people.find_by!(first_name: "Миша"))
    youth.group_memberships.create!(person: guest)

    guest.notes.create!(body: "Пришёл по приглашению Сергея, интересуется молодёжной группой.")
  end
end
puts "Loaded demo data"

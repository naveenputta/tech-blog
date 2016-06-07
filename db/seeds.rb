# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

admin = User.new username: 'admin', password: 'adminqwe', password_confirmation: 'adminqwe', email: '736698959@qq.com', admin: true, activation: 1
puts admin.save! ? 'add admin success.' : 'add admin fail!'

category = Category.new name: 'Default category'
puts category.save! ? 'add category success.' : 'add category fail!'
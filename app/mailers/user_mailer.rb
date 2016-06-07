#encoding: utf-8
class UserMailer < ActionMailer::Base
  helper ApplicationHelper

  default from: Settings.mailer.user_name

  def auth_mail(email, url)
    @url  = url
    mail(subject: "User mailboxes activation email", to: email, date: Time.now)
  end

  def forget_password(email, url)
    @url = url
    mail(subject: 'Forgot password', to: email, date: Time.now)
  end
end

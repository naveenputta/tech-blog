#encoding: utf-8
class UsersController < ApplicationController
  def register
    @user = User.new
    render 'register', layout: 'register'
  end

  def register_confirm
    @user = User.new params.require(:user).permit(:username,:email,:password,:password_confirmation)
    if @user.save
      #to_login @user
      session[:wait_active_email] = @user.email
      redirect_to send_active_mail_users_path
    else
      render 'register', layout: 'register'
    end
  end

  def login
    return redirect_to(login_path(from: referer)) unless params[:from].present?
    @user = User.new
    render 'login', layout: 'register'
  end

  def login_confirm
    @user = User.find_by username: params[:user][:username]
    unless @user.activation?
      session[:wait_active_email] = @user.email
      flash.now[:error] = "User is not active，<a href='#{send_active_mail_users_path}'>Click here</a>Send activation email."
      return render 'login', layout: 'register'
    end
    if @user && @user.check_password(params[:user][:password])
      to_login @user
      @user.update_attribute :last_login_time, DateTime.now
      redirect_to (params[:from].present? ? params[:from] : root_path)
    else
      flash[:error] = 'Wrong username or password'
      render 'login', layout: 'register'
    end
  rescue
    flash[:error] = 'Wrong username or password'
    render 'login', layout: 'register'
  end

  def logout
    session[:user_id] = nil
    redirect_to referer
  end

  def send_active_mail
    @result = {status: false, message: ''}
    if session[:wait_active_email]
      wait_user = User.find_by email: session[:wait_active_email]
      if wait_user.activation?
        flash[:success] = 'Your account has been activated , please visit'
        return redirect_to login_path
      end
      if wait_user.present?
        token = UserActive.generate_token
        active = UserActive.new user_id: wait_user.id, type_name: 'Active', token: token
        url = File.join('http://localhost:3000', "users/activation?token=#{token}")
        if active.save && UserMailer.auth_mail(session[:wait_active_email], url).deliver
          @result[:status] = true
          @result[:message] = session[:wait_active_email]
        end
      end
    end
  end

  def activation
    active = UserActive.where(type_name: 'Active', token: params[:token], used: 0).order('created_at desc').first
    if active && !active.used?
      user = User.find active.user_id
      user.activation = 1
      active.used = 1
      if user.save && active.save
        flash[:success] = 'Activation is successful , log in'
        redirect_to login_path
      else
        flash[:error] = 'Activation failed , please try again , if it is not activated, please contact the administrator'
        redirect_to login_path
      end
    else
      flash[:error] = 'token does not exist'
      redirect_to root_path
    end
  end

  def forget_password
    render 'forget_password', layout: 'register'
  end

  def forget_password_confirm
    @result = {status: false, message: ''}
    if params[:user][:email].present?
      user = User.find_by email: params[:user][:email]
      return redirect_to(root_path) unless user
      token = UserActive.generate_token
      active = UserActive.new user_id: user.id, token: token, type_name: 'ForgetPassword'
      url = File.join('http://localhost:3000', "users/change_pw?token=#{token}")
      if active.save && UserMailer.forget_password(user.email, url).deliver
        @result[:status] = true
        @result[:message] = user.email
      else
        flash.now[:error] = 'Failed to send a message , please try again'
        render 'forget_password', layout: 'register'
      end
    end
  end

  def change_pw
    @token = params[:token]
    active = UserActive.where(type_name: 'ForgetPassword', token: @token, used: 0).order('created_at desc').first
    return redirect_to(root_path) unless active
    if Time.now.to_i - active.created_at.to_i > 600
      return redirect_to root_path
    end
    render 'change_pw', layout: 'register'
  end

  def change_pw_confirm
    @token = params[:user][:token]
    active = UserActive.where(type_name: 'ForgetPassword', token: @token, used: 0).order('created_at desc').first
    return redirect_to(root_path) unless active
    @user = User.find active.user_id
    return redirect_to(root_path) unless @user
    @user.password = params[:user][:password] || ''
    @user.password_confirmation = params[:user][:password_confirmation]
    if @user.save
      flash[:success] = 'Successfully reset your password , please visit'
      redirect_to login_path
    else
      flash.now[:error] = @user.errors.full_messages.first
      render 'change_pw', layout: 'register'
    end
  end

  protected

  def to_login(user)
    session[:user_id] = user.id
  end
end
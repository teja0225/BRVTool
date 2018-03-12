require 'fileutils'
class UsersController < ApplicationController

	def new
  	@user = User.new
  end

  def create
  	#all views are handles in this controller, check for action based on button pressed
  	if params[:submit] 
  		flash[:error]=""
  		flash[:success]=""
	  	@user = User.new(user_params)
	  	begin
	  	#check
	  	if @user.valid?

	  		#connect to mysql
	  		@connection = ActiveRecord::Base.establish_connection(
	           :adapter  => "mysql2",
	           :username => @user[:u],
	           :host     => @user[:host],
	           :password => @user[:p]
	         )

				#get databases available to backup
	  		@result = ActiveRecord::Base.connection.exec_query('SHOW DATABASES')
	  	
	  		#backup All available databases on the server
	  		if @user[:all] == 1

	  			@result.each do |row|

	  				#create directory to store dump
	  				@dir=ENV['HOME']+"/BRV/all/#{row['Database']}"
	  	  		FileUtils.mkdir_p @dir

	  	  		#create dump via bash
	  	  		`mysqldump --user=#{@user[:u]} --password=#{@user[:p]} --host=#{@user[:host]} #{row['Database']}  > #{@dir}/backup.sql`
					  
					  #check status of dump
	  				if $?.exitstatus == 0
	  					f = File.open("#{@dir}/cs.txt",'w');
	  					#on success calculate checksum row wise and store in text file
	  					#the same text file will be used while validation
		  				findDBChecksum @user[:u],@user[:p],@user[:host],row['Database'],f
		  				f.close
	  					flash[:success] = "BackUp success! You can find the backup in #{@dir}"
	  					render 'users/result'
	  				else
	  					flash[:error] = "BackUp Unsuccessful!" 
	  					render 'users/result'
	  				end

					end

	  		else

	  			#create session variables
	  			session[:passed_variable] = "#{@user[:u]}-#{@user[:p]}-#{@user[:host]}-#{@user[:all]}"
	  			render 'users/backup2'

	  		end
	  	
	  	else
	  		render new
	  	end

	  	rescue
	  		#display error message
	  		flash[:error] = "Incorrect Database Credentials!" 
	  		render 'users/result'
	  	end

	  elsif params[:add_db] 
	  	flash[:error]=""
  		flash[:success]=""
	  	begin
	  	@user = User.new(user_params)

	  	#fetch session variables
	  	@user[:u],@user[:p],@user[:host],@user[:all] = session[:passed_variable].split("-");
	  	
	  	#establish connection to database
	  	@connection = ActiveRecord::Base.establish_connection(
	           :adapter  => "mysql2",
	           :username => @user[:u],
	           :host     => @user[:host],
	           :password => @user[:p]
	         )

	  	if @user[:all]== 2

	  		#create directory to store database
	  		@dir=ENV['HOME']+"/BRV/#{@user[:d]}"
	  	  FileUtils.mkdir_p @dir

	  	  #create dump
	  		`mysqldump --user=#{@user[:u]} --password=#{@user[:p]} --host=#{@user[:host]} #{@user[:d]}  > #{@dir}/backup.sql`
					  
	  		if $?.exitstatus == 0
	  			#calculate checksum and store in file
	  			f = File.open("#{@dir}/cs.txt",'w');
		  		findDBChecksum @user[:u],@user[:p],@user[:host],@user[:d],f
		  		f.close
		  		flash[:success] = "BackUp success! You can find the backup in #{@dir}"
		  		render 'users/result'
	  		else
		  		flash[:error] = "BackUp Unsuccessful!" 
		  		render 'users/result'
	  		end
	  	
	  	elsif @user[:all]== 3

	  		#get tables available in the selected database
	  		@result = ActiveRecord::Base.connection.exec_query("SELECT table_name FROM information_schema.tables where table_schema='#{@user[:d]}'")
	  		session[:passed_variable] = "#{@user[:u]}-#{@user[:p]}-#{@user[:host]}-#{@user[:all]}-#{@user[:d]}"
	  		render 'users/backup3'

	  	end
	  	rescue
	  		flash[:error] = "Lost connection to Database!" 
	  		render 'users/result'
	  	end

	  elsif params[:add_tab] 
	  	flash[:error]=""
  		flash[:success]=""
	  	begin
	  	#fetch session variables
	  	@user = User.new(user_params)
	  	@user[:u],@user[:p],@user[:host],@user[:all],@user[:d]= session[:passed_variable].split("-");

	  	#create directory to store dump file
	  	@dir=ENV['HOME']+"/BRV/#{@user[:d]}"
	  	FileUtils.mkdir_p @dir

	  	#create dump
	  	`mysqldump --user=#{@user[:u]} --password=#{@user[:p]} --host=#{@user[:host]} #{@user[:d]} #{@user[:t]}  > #{@dir}/backup.sql`
			
	  	#check status of dump
	  	if $?.exitstatus == 0
	  		#calculate checksum and store it in file
	  		f = File.open("#{@dir}/cs.txt",'w');
		  	findTabChecksum @user[:u],@user[:p],@user[:host],@user[:d],@user[:t],f
		  	f.close
	  		flash[:success] = "BackUp success! You can find the backup in #{@dir}"
	  		render 'users/result'
	  	else
	  		flash[:error] = "BackUp Unsuccessful!" 
	  		render 'users/result'
	  	end
	  	rescue
	  		flash[:error] = "Lost connection to Database!" 
	  		render 'users/result'
	  	end
	  	
	  elsif params[:restore] 
	  	flash[:error]=""
  		flash[:success]=""
	  	begin
	  	@user = User.new(user_params)
	  	#establish connection
	  	@connection = ActiveRecord::Base.establish_connection(
	           :adapter  => "mysql2",
	           :username => @user[:u],
	           :host     => @user[:host],
	           :password => @user[:p]
	         )

	  	#list databases available to load backup into
	  	@result = ActiveRecord::Base.connection.exec_query('SHOW DATABASES')
	  	session[:passed_variable] = "#{@user[:u]}-#{@user[:p]}-#{@user[:host]}"
	  	render 'users/restore2'
	  	rescue
	  		flash[:error] = "Incorrect Database Credentials!" 
	  		render 'users/result'
	  	end

	  elsif params[:add_res_db] 
	  	flash[:error]=""
  		flash[:success]=""
	  	begin
	  	@user = User.new(user_params)
	  	#get session parameters passed
	  	@user[:u],@user[:p],@user[:host]= session[:passed_variable].split("-");
	  	
	  	#fetch file path of sql file to load
			file_data = params[:user][:dir].tempfile.path

			#restore sql file to selected database
	  	`mysql --user=#{@user[:u]} --password=#{@user[:p]} --host=#{@user[:host]} -D #{@user[:d]} < #{file_data}`
	  	
	  	#check status of restore
	  	if $?.exitstatus == 0
	  		flash[:success] = "Restore success!"
	  		render 'users/result'
	  	else
	  		flash[:error] = "Restore Unsuccessful!" 
	  		render 'users/result'
	  	end
	  	rescue
	  		flash[:error] = "Lost connection to Database!" 
	  		render 'users/result'
	  	end

	  elsif params[:validate] 
	  	flash[:error]=""
  		flash[:success]=""
	  	begin
	  	@user = User.new(user_params)
	  	#establish connection to database
	  	@connection = ActiveRecord::Base.establish_connection(
	           :adapter  => "mysql2",
	           :username => @user[:u],
	           :host     => @user[:host],
	           :password => @user[:p]
	         )

	  	if @user[:all] == 3
	  		#fetch session parameters passed
	  		session[:passed_variable] = "#{@user[:u]}$#{@user[:p]}$#{@user[:host]}"
	  		render 'users/validateFile'

	  	else
	  		#fectch databases to show for validation
	  		@result = ActiveRecord::Base.connection.exec_query('SHOW DATABASES')
	  		#construct session parameters passed
	  		session[:passed_variable] = "#{@user[:u]}$#{@user[:p]}$#{@user[:host]}$#{@user[:all]}"
	  		render 'users/validateDB'
	  	end
	  	rescue
	  		flash[:error] = "Incorrect Database Credentials!" 
	  		render 'users/result'
	  	end

	  elsif params[:validate_file]
	  	flash[:error]=""
  		flash[:success]=""
	  	begin
	  	@user = User.new(user_params)
	  	#fetch parameters passed
	  	@user[:u],@user[:p],@user[:host],file_data = session[:passed_variable].split("$");

	  	#establish connection
	  	@connection = ActiveRecord::Base.establish_connection(
	           :adapter  => "mysql2",
	           :username => @user[:u],
	           :host     => @user[:host],
	           :password => @user[:p]
	         )

	  	#file is not yet restored so, create dummy database -> restore -> create checksum -> check -> drop dummy database created
	  	
	  	#create dummy database
	  	ActiveRecord::Base.connection.exec_query('create database dumb')

	  	#get sql file path to load
	  	sql_data = params[:user][:dir].tempfile.path

	  	#perform restore
	  	`mysql --user=#{@user[:u]} --password=#{@user[:p]} --host=#{@user[:host]} -D dumb < #{sql_data}`
	  		
	  	#check status of restore
	 		if $?.exitstatus == 0

	 			#calculate checksum
	  		f = File.open("cs.txt",'w');
	  		findDBChecksum @user[:u],@user[:p],@user[:host],"dumb",f
	  		f.close

	  		#open checksum created
	  		f1 = File.open("cs.txt","r")
	  		#open checksum calculated previously during backup
				f2 = File.open("#{params[:user][:d].tempfile.path}")

				#read content
				content1 = f1.read
				content2 = f2.read

				#skip new lines
				content1.delete!("\n")
				content2.delete!("\n")

				#check contents identity
				if content1==content2
					flash[:success] = "Validation Success! Your files are consistent!"
		  		render 'users/result'	
		  	else
		  		flash[:error] = "Your files are inconsistent!"
		  		render 'users/result'	
		  	end

		  	#drop dummy database created
		  	ActiveRecord::Base.connection.exec_query('drop database dumb')	
	  	else
	  		flash[:error] = "Internal error occurred!"
	  		render 'users/result'
	  	end
	  	rescue
	  		flash[:error] = "Lost connection to Database!" 
	  		render 'users/result'
	  	end

	  elsif params[:validate_db] 
	  	flash[:error]=""
  		flash[:success]=""
	  	begin
	  	@user = User.new(user_params)
	  	#fetch session variables passed
	  	@user[:u],@user[:p],@user[:host],@user[:all] = session[:passed_variable].split("$");
	  	
	  	#establish connection
	  	@connection = ActiveRecord::Base.establish_connection(
	           :adapter  => "mysql2",
	           :username => @user[:u],
	           :host     => @user[:host],
	           :password => @user[:p]
	         )

	  	#validate database
	  	if @user[:all]==1
	  		#calculate checksum for the mentioned database to validate
	  		f = File.open("cs.txt",'w');
	  		findDBChecksum @user[:u],@user[:p],@user[:host],@user[:d],f
	  		f.close

	  		#open checksum file 
				f1 = File.open("cs.txt","r")
				#open checksum calculated previously during backup
				f2 = File.open("#{params[:user][:t].tempfile.path}")

				#read content
				content1 = f1.read
				content2 = f2.read

				#skip new lines
				content1.delete!("\n")
				content2.delete!("\n")

				#check contents identity
				if content1==content2
					flash[:success] = "Validation Success! Your files are consistent!"
	  			render 'users/result'	
	  		else
	  			flash[:error] = "Your files are inconsistent!"
	  			render 'users/result'	
	  		end

		 	elsif @user[:all]==2
		 		#fetch tables in the selected database
		 		@result = ActiveRecord::Base.connection.exec_query("SELECT table_name FROM information_schema.tables where table_schema='#{@user[:d]}'")
	  		#construct session variable to pass
	  		session[:passed_variable] = "#{@user[:u]}-#{@user[:p]}-#{@user[:host]}-#{@user[:d]}"
	  		render 'users/validateTab'

		 	end
		 	rescue
		 		flash[:error] = "Lost connection to Database!" 
	  		render 'users/result'
		 	end

		elsif params[:validate_tab] 
			flash[:error]=""
  		flash[:success]=""
			begin
			@user = User.new(user_params)

			#fetch session var
	  	@user[:u],@user[:p],@user[:host],@user[:d] = session[:passed_variable].split("-");

	  	#establish connection
	  	@connection = ActiveRecord::Base.establish_connection(
	           :adapter  => "mysql2",
	           :username => @user[:u],
	           :host     => @user[:host],
	           :password => @user[:p]
	         )

	  	#calculate checksum for the table to be validated
	  	f = File.open("cs.txt",'w');
	  	findTabChecksum @user[:u],@user[:p],@user[:host],@user[:d],@user[:t],f
	  	f.close

	  	#open checksum file calculated now
	  	f1 = File.open("cs.txt","r")
	  	#open checksum calculated previously during backup
			f2 = File.open("#{params[:user][:dir].tempfile.path}")

			#read content
			content1 = f1.read
			content2 = f2.read

			#skip new lines
			content1.delete!("\n")
			content2.delete!("\n")

			#check for identity
			if content1==content2
				flash[:success] = "Validation Success! Your files are consistent!"
	  		render 'users/result'	
	  	else
	  		flash[:error] = "Your files are inconsistent!"
	  		render 'users/result'	
	  	end
	  	rescue
	  		flash[:error] = "Lost connection to Database!" 
	  		render 'users/result'
	  	end
	  end
  end

private
  def user_params
  	#provide permission to use parameter
  	params.require(:user).permit(:u,:p,:d,:all,:dir,:host,:t)
  end

 	def findDBChecksum(user,password,host,db,f)
 		flash[:error]=""
  	flash[:success]=""
 		begin
 		#establish connection
 		@connection = ActiveRecord::Base.establish_connection(
	           :adapter  => "mysql2",
	           :username => user,
	           :host     => host,
	           :password => password,
	         )

 		#fetch tables in the database
 		@result = ActiveRecord::Base.connection.exec_query("SELECT table_name FROM information_schema.tables where table_schema='#{db}'")
	
		#calculate checksum for each table
	  @result.each do |row|
	  	findTabChecksum user,password,host,db,row['table_name'],f
		end
		rescue
			flash[:error] = "Lost connection to Database!" 
	  	render 'users/result'
		end
 	end

 	def findTabChecksum(user,password,host,db,tab,f)
 		flash[:error]=""
  	flash[:success]=""
 		begin
 		#establish connection
 		@connection = ActiveRecord::Base.establish_connection(
	           :adapter  => "mysql2",
	           :username => user,
	           :host     => host,
	           :password => password,
	         )

 		#fetch column names
 		@result = ActiveRecord::Base.connection.exec_query("select column_name from information_schema.columns where table_schema='#{db}' and table_name='#{tab}'")
 		@MDF_String=""
 		
 		#constrcy Md5 string to pass to MD5 function to calculate checksum of each row
 		#insert 2 between every column to differentiate between ab2cd and abc2d, if any of the columns data will be shuffled
 		@result.each do |row|
	  	@a="IFNULL(#{row['column_name']},\"A\"),\"2\","
	  	@MDF_String="#{@MDF_String}#{@a}"
		end
		@MDF_String="#{@MDF_String}\"2\""

		#calculate table checksum row wise
		@TabCs = ActiveRecord::Base.connection.exec_query("select MD5(concat(#{@MDF_String})) as md5Checksum from #{db}.#{tab}")
 		
		#write row checksum to file
 		@TabCs.each do |row|
	  	f.write(row['md5Checksum'])	
	  	f.write("\n")
		end
		rescue
			flash[:error] = "Lost connection to Database!" 
	  	render 'users/result'
		end
 	end
end
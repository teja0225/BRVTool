class BackupController < ApplicationController
	def new
		@backup = Backup.new
	end
  def create
  	if params[:submit] 
	  	@backup = Backup.new(backup_params)
	  	if @backup.valid?
	  		@connection = ActiveRecord::Base.establish_connection(
	           :adapter  => "mysql2",
	           :backupname => @backup[:u],
	           :host     => @backup[:host],
	           :password => @backup[:p]
	         )
	
	  		@result = ActiveRecord::Base.connection.exec_query('SHOW DATABASES')

	  		if @backup[:all] == 1

	  			@result.each do |row|

	  				@dir=ENV['HOME']+"all/#{row['Database']}"
	  	  		FileUtils.mkdir_p @dir

	  				`mysqldump -u #{@backup[:u]} -p#{@backup[:p]} --databases #{row['Database']} > #{@dir}/backup.sql`
					  
					  f = File.open("#{@dir}/cs.txt",'w');
	  				findDBChecksum @backup[:u],@backup[:p],@backup[:host],row['Database'],f
	  				f.close

	  				flash[:success] = "Backup success!"
	  				render 'static_pages/backupSuccess'

					end

	  		else

	  			session[:passed_variable] = "#{@backup[:u]}-#{@backup[:p]}-#{@backup[:host]}-#{@backup[:all]}"
	  			render 'static_pages/backup2'

	  		end
	  	
	  	else
	  		render new
	  	end

	  elsif params[:add_db] 

	  	@backup = Backup.new(backup_params)
	  	@backup[:u],@backup[:p],@backup[:host],@backup[:all] = session[:passed_variable].split("-");

	  	@connection = ActiveRecord::Base.establish_connection(
	           :adapter  => "mysql2",
	           :backupname => @backup[:u],
	           :host     => @backup[:host],
	           :password => @backup[:p],
	         )

	  	if @backup[:all]== 2

	  		@dir=ENV['HOME']+"/#{@backup[:d]}"
	  	  FileUtils.mkdir_p @dir

	  		`mysqldump -u #{@backup[:u]} -p#{@backup[:p]} --databases #{@backup[:d]} > #{@dir}/backup.sql`

	  		f = File.open("#{@dir}/cs.txt",'w');
	  		findDBChecksum @backup[:u],@backup[:p],@backup[:host],@backup[:d],f
	  		f.close
	  		flash[:success] = "Backup success!"
	  	  render 'static_pages/backupSuccess'
	  	
	  	elsif @backup[:all]== 3

	  		@result = ActiveRecord::Base.connection.exec_query("SELECT table_name FROM information_schema.tables where table_schema='#{@backup[:d]}'")
	  		session[:passed_variable] = "#{@backup[:u]}-#{@backup[:p]}-#{@backup[:host]}-#{@backup[:all]}-#{@backup[:d]}"
	  		render 'static_pages/backup3'

	  	end

	  elsif params[:add_tab] 

	  	@backup = Backup.new(backup_params)
	  	@backup[:u],@backup[:p],@backup[:host],@backup[:all],@backup[:d]= session[:passed_variable].split("-");

	  	@dir=ENV['HOME']+"/#{@backup[:d]}"
	  	FileUtils.mkdir_p @dir

	  	`mysqldump -u #{@backup[:u]} -h #{@backup[:host]} -p#{@backup[:p]} #{@backup[:d]} #{@backup[:t]} > #{@dir}/backup.sql`
	    
	    f = File.open("#{@dir}/cs.txt",'w');
	  	findTabChecksum @backup[:u],@backup[:p],@backup[:host],@backup[:d],@backup[:t],f
	  	f.close

	  	flash[:success] = "Backup success!"
	  	render 'static_pages/backupSuccess'

	  end
  end

private
  def backup_params
  	params.require(:backup).permit(:u,:p,:d,:all,:dir,:host,:t)
  end

 	def findDBChecksum(backup,password,host,db,f)
 		@connection = ActiveRecord::Base.establish_connection(
	           :adapter  => "mysql2",
	           :backupname => backup,
	           :host     => host,
	           :password => password,
	         )
 		@result = ActiveRecord::Base.connection.exec_query("SELECT table_name FROM information_schema.tables where table_schema='#{db}'")
	  @result.each do |row|
	  	findTabChecksum backup,password,host,db,row['table_name'],f
		end
 	end

 	def findTabChecksum(backup,password,host,db,tab,f)
 		@connection = ActiveRecord::Base.establish_connection(
	           :adapter  => "mysql2",
	           :backupname => backup,
	           :host     => host,
	           :password => password,
	         )
 		@result = ActiveRecord::Base.connection.exec_query("select column_name from information_schema.columns where table_schema='#{db}' and table_name='#{tab}'")
 		@MDF_String=""
 		@result.each do |row|
	  	@a="IFNULL(#{row['column_name']},\"A\"),\"2\","
	  	@MDF_String="#{@MDF_String}#{@a}"
		end
		@MDF_String="#{@MDF_String}\"2\""
		@TabCs = ActiveRecord::Base.connection.exec_query("select MD5(concat(#{@MDF_String})) as md5Checksum from #{db}.#{tab}")
 		@TabCs.each do |row|
	  	f.write(row['md5Checksum'])	
	  	f.write("\n")
		end
 	end
end
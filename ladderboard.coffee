# Code that runs on the client
if Meteor.is_client

	# Create a variable for a client-side DB that syncs with the server-side DB 'entries'
	Entries = new Meteor.Collection 'entries'

	# Local variable to store current login cookie
	_cookie = null

	# 'Entries' item of leaderboard template 
	# is just the whole db sorted by wins in reverse
	Template.leaderboard.entries = ->
		return Entries.find {}, sort: {wins: -1}

	# leaderboard and entry template have the same isAdmin function
	# returns if Session.isAdmin == _cookie
	Template.leaderboard.isAdmin = Template.entry.isAdmin = ->
		Session.get 'isAdmin'
		return Session.equals 'isAdmin', _cookie

	# Creates a new editable field in the list
	# with given properties, blank defaults if no properties given
	newEdit = (name,wins,points,rep) ->
		id = Entries.insert 
			name: name or ''
			wins: wins or ''
			points: points or ''
			rep: rep or ''
		Session.set "editing-#{id}", true

	# All the events for the leaderboard template
	Template.leaderboard.events =
		'click #logout': ->
			Session.set 'isAdmin', false
		'click #auth': ->
			# Hides/shows login-form
			$("#login-form").toggle()
		'click #addnew': ->
			# Add new just creates a new blank editable item
			newEdit()
		'click #submit-login': ->
			# Calls the server's login function with username/password field values
			Meteor.call 'login', $('#login-text').val(), $('#password-text').val(), 
			# Once server responds, it will call the below function
			(error, result) ->
				if error?
					# If error, show it and hide the login form for 1.5sec
					$('#error-text').text('Error: '+error.reason).show()
					$('#login-form').toggle()
					$("#auth").hide()
					Meteor.setTimeout ->
						$('#error-text').hide()
						$("#auth").show()
						$("#login-form").show()
					, 1500
				else
					# Else, set local cookie variable and isAdmin to the returned cookie
					_cookie = result
					Session.set 'isAdmin', result



	# Whether an entry is being edited right now, for the template
	Template.entry.editing = ->
		return Session.get "editing-#{@_id}"

	# all the events for an entry, save/edit/delete
	Template.entry.events = 
		'click #save': ->
			Entries.update { _id: @_id },
				name: $("#input-name").val()
				wins: $("#input-wins").val()
				points: $("#input-points").val()
				rep: $("#input-rep").val()
			Session.set "editing-#{@_id}", false

		'click #edit': ->
			# Hack: When editing an entry, have to remove the entry then
			# re-add it as editable in the same place for it  to show up right in the table
			newEdit @name, @wins, @points, @rep
			Entries.remove _id: @_id
				
		'click #delete': ->
			# Delete the entry
			Entries.remove { _id: @_id }


			

# Code that runs on the server
if Meteor.is_server

	# Creates server-side db and allows client-side to have an 'entries' db
	new Meteor.Collection 'entries'

	# Makes a cookie (random string) of length len
	makeCookie = (len) ->
		chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
		cookie = ""
		for i in [1..len]
			index = Math.floor Math.random()*chars.length
			cookie += chars.substring index, index+1
		return cookie

	# Meteor.methods has all the methods that the client can call
	Meteor.methods
		# Called by client with Meteor.call 'login'
		login: (username, password) ->
			if username is "admin" and password is "admin"
				# If successful, make a cookie of length 15
				return makeCookie 15
			else
				 # Else, throw a bad username/pass error and 401 (unauthorized)
				throw new Meteor.Error 401, "Bad username or password!"

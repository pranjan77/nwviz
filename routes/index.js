
var SHOCK = require('shock');
var _ 	  = require('underscore');

var url = 'http://140.221.84.236:8000/node';
var un = 'gpuser';
var ps = 'bescdemo';


exports.index = function(req, res){
  res.render('index', { title: 'Network Workbench' });
};

exports.vis = function(req, res){
	var id = req.params.id;

	var shock3 = new SHOCK( url, un, ps );
	shock3.getFile(id, function(error, file) {
		if (error) {
  			res.render('index', { title: 'Network Workbench' });
			console.dir(error);
		} else {
			console.dir(file);
  			res.render('index', { data : file});
		}
	});
};

exports.gvis = function(req, res){
	var id = req.params.id;

	var shock3 = new SHOCK( url, un, ps );
	shock3.getFile(id, function(error, file) {
		if (error) {
  			res.render('index', { title: 'Network Workbench' });
			console.dir(error);
		} else {
			//console.dir(file);
			var modules = _.values( file.module );
			
			/*
			var shock4 = new SHOCK( url, un, ps );
			shock4.getFile(modules[0].shockId, function(error, content) {
				if (error) {
					res.render('index', { title: 'Network Workbench' });
					console.dir(error);
				} else {
					res.render('index2', { data : file, first: content});
				}
			});
			*/
  			res.render('index2', { data : file, first: modules[0].shockId });
		}
	});
};

exports.getData = function(req, res){
	var id = req.params.shockId;
	console.log('id = ' + id );

	var shock3 = new SHOCK( url, un, ps );
	shock3.getFile(id, function(error, data) {
		//console.dir(data);
		if (error) {
			console.log(error);
			res.json(500, error);
		} else {
			res.json(200, data);
		}
	});
};

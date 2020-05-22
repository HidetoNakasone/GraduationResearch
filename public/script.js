
var founded_maker_list = [];
var founded_maker_list_values = [];

AFRAME.registerComponent('registerevents', {
  init: function () {
    var marker = this.el;
    var res_ele = document.getElementById('results_wrap');
    var res_ele_2 = document.getElementById('image_wrap');

    marker.addEventListener('markerFound', function () {
      var marker_id = marker.dataset.marker_id;
      console.log(marker_id + ' の検知を確認');
      founded_maker_list.push(marker_id);
      myAjax_1(founded_maker_list);

      res_ele.style.display = "block";

      console.log(founded_maker_list);
    });

    marker.addEventListener('markerLost', function () {
      var marker_id = marker.dataset.marker_id;
      console.log(marker_id + ' ロスト');
      idx = founded_maker_list.indexOf(marker_id);
      founded_maker_list.splice(idx, 1);
      myAjax_1(founded_maker_list);

      res_ele_2.style.display = "none";

      console.log(founded_maker_list);
    });
  }
});

var xhr = new XMLHttpRequest();
function myAjax_1(founded_maker_list) {
  xhr.open('get', '/my_ajax?marker_list=' + founded_maker_list);
  xhr.setRequestHeader('content-type', 'application/x-www-form-urlencoded charset=UTF-8');
  xhr.send();
  xhr.onreadystatechange = function() {
    if(xhr.readyState === 4) {
      if(xhr.status === 200) {
        res = JSON.parse(xhr.responseText);
        resultsView(res);
      }
    }
  }
}

function resultsView(res) {
  var res_ele = document.getElementById('results_wrap');
  msg = " "
  for(var i = 0; i < res.length; i++) {
    msg += res[i] + " "
  }
  res_ele.firstElementChild.innerHTML = msg;

  if (res.length == 0) {
    res_ele.style.display = 'none';
  }

  if (founded_maker_list.length >= 2) {
    myAjax_2(founded_maker_list);
  }
}

function myAjax_2(founded_maker_list) {
  var res_ele_2 = document.getElementById('image_wrap');
  xhr.open('get', '/my_ajax_2?marker_list=' + founded_maker_list);
  xhr.setRequestHeader('content-type', 'application/x-www-form-urlencoded charset=UTF-8');
  xhr.send();
  xhr.onreadystatechange = function() {
    if(xhr.readyState === 4) {
      if(xhr.status === 200) {
        res = JSON.parse(xhr.responseText);
        var res_ele_2 = document.getElementById('image_wrap');
        res_ele_2.firstElementChild.src = res
        res_ele_2.style.display = "block";
      }
    }
  }
}

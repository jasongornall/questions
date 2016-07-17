// Generated by CoffeeScript 1.8.0
var msnry, ref;

msnry = null;

ref = new Firebase("https://question-everything.firebaseio.com");

ref.authAnonymously(function(err, data) {
  var renderQuestion;
  renderQuestion = function(link, previous) {
    var $questions, getNextQ;
    if (link == null) {
      link = "head";
    }
    if (previous == null) {
      previous = false;
    }
    getNextQ = function(finish) {
      if (link) {
        return ref.child(link).orderByChild("vote_inverse").once('value', function(doc) {
          console.log(doc.val());
          return finish(doc);
        });
      } else {
        return finish(null);
      }
    };
    $('body .questions-container').html(teacup.render(function() {
      return div('.questions');
    }));
    $questions = $('body .questions');
    $(window).off('resize', function() {});
    $(window).on('resize', function() {
      var width;
      width = Math.floor($(window).width() / 340);
      return $('.questions-container').css('max-width', "" + (width * 340) + "px");
    });
    return getNextQ(function(doc) {
      var $new_question;
      if (doc !== null) {
        doc.forEach(function(child_doc) {
          var $question, answer_1, answer_2, item, question, vote, _ref;
          _ref = (child_doc != null ? child_doc.val() : void 0) || {}, question = _ref.question, answer_1 = _ref.answer_1, answer_2 = _ref.answer_2, vote = _ref.vote;
          if (!(question && answer_1 && answer_2)) {
            return false;
          }
          item = localStorage.getItem(child_doc.key()) || {};
          $question = $(teacup.render(function() {
            return div('.question', {
              'data-key': child_doc.key()
            }, function() {
              div('.voting', function() {
                div({
                  'data-arrow': 'up'
                });
                div(".vote", function() {});
                return div({
                  'data-arrow': 'down'
                });
              });
              div('.question-header', function() {
                return question;
              });
              return div('.answers', function() {
                div('.answer_1', {
                  'data-next': answer_1.next
                }, function() {
                  return answer_1.text;
                });
                return div('.answer_2', {
                  'data-next': answer_2.next
                }, function() {
                  return answer_2.text;
                });
              });
            });
          }));
          $questions.append($question);
          return (function($question) {
            $question.find('[data-arrow]').on('click', function(e) {
              var $el, incriment, modified_incriment;
              $el = $(e.currentTarget);
              debugger;
              incriment = $el.data('arrow') === 'up' ? 1 : -1;
              item = JSON.parse(localStorage.getItem(child_doc.key()) || '{}');
              modified_incriment = incriment;
              if (item.vote === incriment) {
                modified_incriment = incriment * -1;
                incriment = 0;
              } else if (item.vote === incriment * -1) {
                modified_incriment = incriment * 2;
              }
              item.vote = incriment;
              item.vote_inverse = incriment * -1;
              localStorage.setItem(child_doc.key(), JSON.stringify(item));
              return ref.child("" + link + "/" + (child_doc.key()) + "/vote").once('value', function(current_vote_doc) {
                var currentVote, new_val;
                currentVote = (current_vote_doc != null ? current_vote_doc.val() : void 0) || 0;
                new_val = currentVote + modified_incriment;
                ref.child("" + link + "/" + (child_doc.key()) + "/vote").set(new_val);
                return ref.child("" + link + "/" + (child_doc.key()) + "/vote_inverse").set(new_val * -1);
              });
            });
            ref.child("" + link + "/" + (child_doc.key()) + "/vote").on('value', function(vote_doc) {
              var $vote, local_vote, new_vote;
              new_vote = (vote_doc != null ? vote_doc.val() : void 0) || 0;
              $vote = $question.find('.vote');
              $vote.html("" + new_vote);
              $vote.toggleClass('bad', new_vote < 0);
              $vote.toggleClass('good', new_vote > 5);
              item = JSON.parse(localStorage.getItem(child_doc.key()) || '{}');
              debugger;
              local_vote = 'none';
              if (item.vote > 0) {
                local_vote = 'up';
              } else if (item.vote < 0) {
                local_vote = 'down';
              }
              return $question.attr('data-vote', local_vote);
            });
            $question.find('.answers > div').on('click', function(e) {
              var $el, key, key_previous, next;
              $el = $(e.currentTarget);
              next = $el.data('next');
              key = $el.closest('.question').data('key');
              key_previous = "" + link + "/" + key + "/" + ($el.attr('class'));
              ref.child("" + key_previous + "/count").transaction(function(currentCount) {
                if (currentCount == null) {
                  currentCount = 0;
                }
                return currentCount + 1;
              });
              return renderQuestion(next, key_previous);
            });
            return false;
          })($question);
        });
      }
      $new_question = $(teacup.render(function() {
        return div('.question', function() {
          return form(function() {
            div('.text-area-container', function() {
              textarea('.question-header', {
                maxlength: 250,
                placeholder: "Add your own question",
                required: true
              });
              div('.resizer question-header', function() {
                return 'A';
              });
              return div('.characters', function() {
                return '';
              });
            });
            div('.answers', function() {
              div('.text-area-container', function() {
                textarea('.answer_1', {
                  maxlength: 140,
                  placeholder: 'Put answer one here',
                  required: true
                });
                div('.resizer answer_1', function() {
                  return 'A';
                });
                return div('.characters', function() {
                  return '';
                });
              });
              return div('.text-area-container', function() {
                textarea('.answer_2', {
                  maxlength: 140,
                  placeholder: 'Put answer two here',
                  required: true
                });
                div('.resizer answer_2', function() {
                  return 'A';
                });
                return div('.characters', function() {
                  return '';
                });
              });
            });
            return input({
              type: 'submit',
              value: 'submit'
            });
          });
        });
      }));
      (function($new_question) {
        $questions.append($new_question);
        $new_question.find('textarea').on('input', function(e) {
          var $el, maxlength;
          $el = $(e.currentTarget);
          $el.next().html("" + ($el.val() || 'A') + "\n\n");
          maxlength = $el.attr('maxlength');
          return $el.siblings('.characters').html(maxlength - $el.val().length);
        });
        return $new_question.find('form').on('submit', function(e) {
          var $el, new_q;
          if (!link) {
            link = "leaf/" + (ref.child('leaf').push().key());
          }
          $el = $(e.currentTarget);
          new_q = ref.child(link).push();
          new_q.set({
            answer_1: {
              text: $el.find('textarea.answer_1').val()
            },
            answer_2: {
              text: $el.find('textarea.answer_2').val()
            },
            question: $el.find('textarea.question-header').val()
          }, function() {
            var question_location;
            question_location = "" + link + "/" + (new_q.key());
            return ref.child("" + previous + "/next").set(link, function() {
              return renderQuestion(link, previous);
            });
          });
          return false;
        });
      })($new_question);
      $('.questions').masonry({
        itemSelector: '.question',
        layoutPriorities: {
          upperPosition: 1,
          shelfOrder: 1
        }
      });
      msnry = $('.questions').data('masonry');
      return $(window).trigger('resize');
    });
  };
  return renderQuestion();
});

msnry = null
ref = new Firebase "https://question-everything.firebaseio.com"

NAV = {
  'home': 'home'
  'faq': 'faq'
  'exp': 'what is this'
  'graph': 'view graph'
}
SUBJECTS = {
  'fun': 'Fun'
  'serious': 'Serious'
  'stories': 'Stories'
  'test': 'testing'
}
TIMES  = {
  'hour': 'past hour'
  'day': 'past 24 hours'
  'year': 'past year'
  'all': 'all time'
}
authedData = null
start_time = 0
end_time = Date.now()
past_questions = []
ref.authAnonymously (err, data) ->
  renderHeader = ->

    $header = $('body > .container > .header')
    nav_selected = 'home'
    subject_selected = 'test'
    times_selected = 'all'

    $header.html teacup.render ->
      div '.nav', ->
        for key, val of NAV
          div '.nav-item', 'data': {
            'nav': key
            'selected': "#{key is nav_selected}"
          }, -> val
      div '.subjects', ->
        for key, val of SUBJECTS
          div '.subject', 'data': {
            subject: key
            selected: "#{key is subject_selected}"
          }, -> val
      div '.times', ->
        for key, val of TIMES
          div '.time', 'data': {
            time: key
            selected: "#{key is times_selected}"
          }, -> val

    $header.find('.nav-item').on 'click', (e) ->
      $el = $ e.currentTarget
      $el.siblings().attr 'data-selected', false
      $el.attr 'data-selected', true

    $header.find('.subjects .subject').on 'click', (e) ->
      $el = $ e.currentTarget
      $el.siblings().attr 'data-selected', false
      $el.attr 'data-selected', true
      renderQuestion $el.data 'subject'

    $header.find('.time').on 'click', (e) ->
      $el = $ e.currentTarget
      $el.siblings().attr 'data-selected', false
      $el.attr 'data-selected', true
      $questions = $('body .questions')
      renderQuestion $questions.data('link'), $questions.data('previous')

  questionHtml = (data, wrapper = '.question') ->
    {question, vote, title, key, answer, link} = data or {}
    item = localStorage.getItem(key) or {}
    return teacup.render ->
      div wrapper, 'data-key': key, 'data-link': link, ->
        if not answer
          div '.voting', ->
            div 'data-arrow':'up'
            div ".vote", ->
            div 'data-arrow':'down'
        div '.question-title', -> title
        div '.question-body', -> question
        flag = true
        div '.answers', ->
          for opt in [1..4]
            ans = data["answer_#{opt}"]
            continue unless ans
            div ->
              span '.text', data: {
                answer: "answer_#{opt}"
                next: ans.next
                selected: answer is "answer_#{opt}"
              }, -> ans.text
              span '.count', -> "#{ans.count or 0}"
            flag = flag and ans.next
        if not flag and not answer
          div '.asterisk', -> 'dead end'
  renderQuestion = (link = "test", previous = false) ->
    past_questions = [] unless previous

    # make sure we have the right time
    time = $('body > .container > .header .time[data-selected=true]').data('time') or 'all'
    switch time
      when 'hour'
        start_time = Date.now() - 60 * 60 * 1000
      when 'day'
        start_time = Date.now() - 24 * 60 * 60 * 1000
      when 'year'
        start_time = Date.now() - 365 * 24 * 60 * 60 * 1000
      when 'all'
        start_time = 0

    getNextQ = (finish) ->
      if link
        ref.child(link).orderByChild('created').startAt(start_time).endAt(Date.now()).once 'value', (doc) ->
          # get items
          items = doc.val() or {}

          # convert to array
          new_items = []
          for key, val of items
            val.key = key
            val.link = link
            new_items.push val

          # sort array by vote
          new_items = new_items.sort (a, b) ->
            b.vote - a.vote

          # return new items
          finish new_items
      else
        finish null

    $('body .questions-container').html teacup.render ->
      div '.questions'

    $questions = $('body .questions')
    $questions.attr('data-link', link)
    $questions.attr('data-previous', previous)
    $(window).off 'resize', ->
    $(window).on 'resize', ->
      width = Math.floor $(window).width() / 340
      $('.questions-container').css 'max-width', "#{width * 340}px"

    getNextQ (new_items) ->
      if new_items?.length
        new_items.forEach (child_item) ->
          {question, vote, title, key} = child_item or {}
          return false unless question and title
          item = localStorage.getItem(key) or {}
          $question = $ questionHtml child_item

          $questions.append $question
          do ($question) ->
            $question.find('[data-arrow]').on 'click', (e) ->
              $el = $ e.currentTarget
              incriment = if $el.data('arrow') is 'up' then 1 else -1
              item = JSON.parse localStorage.getItem(key) or '{}'
              modified_incriment = incriment
              if item.vote is incriment
                modified_incriment = incriment * -1
                incriment = 0
              else if item.vote is incriment * -1
                modified_incriment = incriment * 2

              item.vote = incriment

              # stupid yes but firebase doesn't support reverse order
              item.vote_inverse = incriment * -1
              localStorage.setItem key, JSON.stringify item

              ref.child("#{link}/#{key}/vote").once 'value', (current_vote_doc) ->
                currentVote = current_vote_doc?.val() or 0
                new_val = currentVote + modified_incriment
                ref.child("#{link}/#{key}/vote").set new_val
                ref.child("#{link}/#{key}/vote_inverse").set new_val * -1

            ref.child("#{link}/#{key}/vote").on 'value', (vote_doc) ->
              new_vote = vote_doc?.val() or 0
              $vote = $question.find('.vote')
              $vote.html "#{new_vote}"
              $vote.toggleClass 'bad', new_vote < 0
              $vote.toggleClass 'good', new_vote > 5

              item = JSON.parse localStorage.getItem(key) or '{}'
              local_vote = 'none'
              if item.vote > 0
                local_vote = 'up'
              else if item.vote < 0
                local_vote = 'down'
              $question.attr 'data-vote', local_vote

            $question.find('.answers .text').on 'click', (e) ->
              $el = $ e.currentTarget
              next = $el.data('next')
              key = $el.closest('.question').data 'key'
              key_previous = "#{link}/#{key}/#{$el.data('answer')}"
              ref.child("#{key_previous}/count").transaction ((currentCount) ->
                currentCount ?= 0
                return currentCount + 1
              ), (error, committed, ss) ->
                return if err
                return if not committed
                child_item.answer = $el.data 'answer'
                child_item[child_item.answer].count = ss.val()
                past_questions.unshift child_item
                renderQuestion next, key_previous
            return false

      else
        $questions.append $ teacup.render ->
          div '.question.no-border', ->
            span -> 'Oops looks like the end of the road,
            no content yet.. click the box to add some!'
      $new_question = $ teacup.render ->
        div '.question', ->
          div '.open-pop', -> if previous then 'add branch at this point' else 'Create new story'
          if previous
            div '.past', 'data-count': 0, ->
              div '.topic', -> 'previous answers'
              div '.options', ->
                i ".material-icons.back", 'data-disabled': "#{past_questions.length is 1}", ->
                 'navigate_before'
                span '.jump', -> 'jump here'
                i '.material-icons.next', 'data-disabled': "true", -> 'navigate_next'
              div '.old-questions', ->
                raw questionHtml past_questions[0], '.old-question'
          div '.modalDialog', ->
            div '.new-question', ->
              h3 -> 'Submitting a new Post'
              span class: 'close', -> 'X'
              form ->
                div '.text-area-container', ->
                  textarea '.question-title', 'data-maxlength': 120, placeholder: "Add title", required: true
                  div '.resizer question-body', -> 'A'
                  div '.characters', -> ''
                div '.text-area-container', ->
                  textarea '.question-body', 'data-maxlength': 250, placeholder: "Add your body", required: true
                  div '.resizer question-body', -> 'A'
                  div '.characters', -> ''
                div '.answers', ->
                  for opt in [1..4]
                    div '.text-area-container', ->
                      required = opt is 1
                      placeholder = if required then 'Put choice here' else 'Put (optional) choice here'
                      textarea ".answer_#{opt}", 'data-maxlength': 140, placeholder: placeholder, required: required
                      div '.resizer', -> 'A'
                      div '.characters', -> ''
                input type:'submit', value: 'submit'
      do ($new_question) ->
        $questions.prepend $new_question

        $questions.find('.open-pop, .close').on 'click', ->
          $new_question.find('.modalDialog').toggleClass 'visible'

        $new_question.find('.options .jump').on 'click', (e) ->
          $el = $ e.currentTarget
          index = $el.closest('.past').data 'count'
          previous = false
          if past_questions[index+1]
            {key, link, answer} =  past_questions[index+1]
            key_previous = "#{link}/#{key}/#{answer}}"

          old_link = past_questions[index].link

          past_questions.splice(0, index + 1)
          renderQuestion old_link, key_previous

        $new_question.find('.options .back, .options .next').on 'click', (e) ->
          $el = $ e.currentTarget
          $past = $el.closest('.past')
          return if $el.attr('data-disabled') is 'true'

          index = $el.closest('.past').data 'count'

          new_index = index + if $el.hasClass('back') then 1 else -1

          $el.closest('.past').data 'count', new_index
          $old_q = $past.find('.old-questions')
          $past.find('.back').attr('data-disabled', "#{not Boolean past_questions[new_index + 1]}")
          $past.find('.next').attr('data-disabled', "#{not Boolean past_questions[new_index - 1]}")
          $old_q.html questionHtml past_questions[new_index], '.old-question'
          window.msnry.masonry()

        $new_question.find('textarea').on 'input', (e) ->
          $el = $ e.currentTarget
          maxlength = $el.attr 'data-maxlength'
          str = $el.val().slice 0, maxlength
          $el.val str

          if str.length is 0
            $el.next().html ""
            $el.siblings('.characters').html ''
          else
            $el.next().html "#{str}\n\n"
            $el.siblings('.characters').html maxlength - str.length
          return false

        $new_question.find('form').on 'submit', (e) ->
          if not link
            link = "leaf/#{ref.child('leaf').push().key()}"
          $el = $ e.currentTarget
          new_q = ref.child(link).push()
          new_q_obj = {
            answer_1:
              text: $el.find('textarea.answer_1').val()
            question: $el.find('textarea.question-body').val()
            title: $el.find('textarea.question-title').val()
            created: Firebase.ServerValue.TIMESTAMP
            vote: 0
            vote_inverse: 0
          }

          # handle skips
          c = 2
          for opt in [2..4]
            answer = $el.find("textarea.answer_#{opt}").val()
            continue unless answer
            new_q_obj["answer_#{c}"] = {text: answer}
            c++

          new_q.set new_q_obj, ->
            return renderQuestion(link, previous) unless previous
            question_location = "#{link}/#{new_q.key()}"
            ref.child("#{previous}/next").set link, ->
              debugger;
              renderQuestion link, previous
          return false





      window.msnry = $('.questions').masonry {
        itemSelector: '.question'
        layoutPriorities:
          upperPosition: 1
          shelfOrder: 1
      }
      $('.questions').data 'masonry'
      $(window).trigger('resize')


  renderHeader()
  renderQuestion 'test'





;; @file    <services/github.cljs>
;; @author  <wakaranakattari@gmail.com>
;; @info    <github fetch api for dynamic loading repos>
;; @license <gpl 3.0>
;; @version <2.0.0>
;; @since   <2026-05-07>

;; @secstart->@secname <ns>
(ns bio-site.services.github) ;; @info <ns and file for my bio site>
;; @secend->@secname   <ns>

;; @secstart->@secname <fetchrepos>
  ;; @funcinfo <fetch github repos, async, takes two callbacks: on-success (repos) and on-error (err-msg)>
  ;; @param <on-success: fn - called with filtered repo list>
  ;; @param <on-error: fn - called with error message>
  ;; @return <promise - fetch chain>
  ;; @complexity <o(n) over repos>
(defn fetch-repos!
  [on-success on-error]

  ;; @info <getting fetch via api>
  (-> (js/fetch "https://api.github.com/users/wakaranakattari/repos?sort=updated&per_page=100")
      ;; @info <if getting fetch is successfully, trying parse to json>
      (.then #(.json %))
      ;; @info <if parse to json is successfully, convert to clj map and filter out forked repos>
      (.then (fn [data]
               (let [repos (js->clj data :keywordize-keys true)
                     filtered (filter #(not (:fork %)) repos)]

                ;; @info <if convert to clj map etc is successfully>
                 (on-success filtered))))

      ;; @info <if fetch via api || parse to json || convert to clj map is failed>
      (.catch (fn [err]
                (on-error (.-message err))))))
;; @secend->@secname   <fetchrepos>

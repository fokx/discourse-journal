import { scheduleOnce } from "@ember/runloop";
import discourseComputed from "discourse/lib/decorators";
import KeyboardShortcuts from "discourse/lib/keyboard-shortcuts";
import { withPluginApi } from "discourse/lib/plugin-api";

const PLUGIN_ID = "discourse-journal";

export default {
  name: "journal-topic",
  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (!siteSettings.journal_enabled) {
      return;
    }

    withPluginApi("0.8.12", (api) => {
      api.modifyClass("route:topic", {
        pluginId: PLUGIN_ID,

        isJournal() {
          const controller = this.controllerFor("topic");
          const topic = controller.get("model");
          return topic.journal;
        },

        actions: {
          didTransition() {
            if (this.isJournal()) {
              KeyboardShortcuts.pause(["c"]);
              $("body").addClass("topic-journal");
            }
            return this._super(...arguments);
          },

          willTransition() {
            if (this.isJournal()) {
              KeyboardShortcuts.unpause(["c"]);
              $("body").removeClass("topic-journal");
            }
            return this._super(...arguments);
          },
        },
      });

      api.modifyClass("model:topic", {
        pluginId: PLUGIN_ID,

        @discourseComputed("journal")
        showJournalTip(journalEnabled) {
          return journalEnabled && siteSettings.journal_show_topic_tip;
        },

        @discourseComputed(
          "highest_post_number",
          "url",
          "last_entry_post_number"
        )
        lastPostUrl(highestPostNumber, url, lastEntryPostNumber) {
          return lastEntryPostNumber
            ? this.urlForPostNumber(lastEntryPostNumber)
            : this.urlForPostNumber(highestPostNumber);
        },
      });

      api.modifyClass("component:topic-footer-buttons", {
        pluginId: PLUGIN_ID,

        didInsertElement() {
          this._super(...arguments);

          const journalEnabled = this.get("topic.journal");
          if (journalEnabled) {
            scheduleOnce("afterRender", () => {
              $(
                ".topic-footer-main-buttons > button.create",
                this.element
              ).hide();
            });
          }
        },
      });

      api.modifyClass("component:topic-progress", {
        pluginId: PLUGIN_ID,

        @discourseComputed(
          "progressPosition",
          "topic.last_read_post_id",
          "topic.journal"
        )
        showBackButton(position, lastReadId, journalEnabled) {
          if (journalEnabled) {
            return false;
          } else {
            return this._super(...arguments);
          }
        },
      });

      /*function renderParticipants(userFilters, participants) {
        if (!participants) {
          return;
        }

        userFilters = userFilters || [];
        return participants.map(p => {
          return this.attach("topic-participant", p, {
            state: { toggled: userFilters.includes(p.username) }
          });
        });
      }*/

      //TODO This breaks in 3.2.x due to missing topic-participant widget.
      //   api.reopenWidget("topic-map-summary", {
      //   html(attrs, state) {
      //     if (attrs.journal) {
      //       return this.journalMap(attrs, state);
      //     } else {
      //       return this._super(attrs, state);
      //     }
      //   },

      //   journalMap(attrs, state) {
      //     const contents = [];
      //     const post = this.findAncestorModel();
      //     const topic = post.topic;

      //     contents.push(
      //       h("li", [
      //         h("h4", I18n.t("created_lowercase")),
      //         h("div.topic-map-post.created-at", [
      //           avatarFor("tiny", {
      //             username: attrs.createdByUsername,
      //             template: attrs.createdByAvatarTemplate,
      //             name: attrs.createdByName
      //           }),
      //           dateNode(attrs.topicCreatedAt)
      //         ])
      //       ])
      //     );

      //     let lastEntryUrl = attrs.topicUrl + "/" + topic.last_entry_post_number;

      //     contents.push(
      //       h(
      //         "li",
      //         h("a", { attributes: { href: lastEntryUrl } }, [
      //           h("h4", I18n.t(`last_entry_lowercase`)),
      //           h("div.topic-map-post.last-entry", [
      //             avatarFor("tiny", {
      //               username: topic.journal_author.username,
      //               template: topic.journal_author.avatar_template,
      //               name: topic.journal_author.name
      //             }),
      //             dateNode(attrs.lastPostAt)
      //           ])
      //         ])
      //       )
      //     );

      //     contents.push(
      //       h("li", [
      //         numberNode(topic.entry_count),
      //         h(
      //           "h4",
      //           I18n.t(`entry_lowercase`, { count: topic.entry_count })
      //         )
      //       ])
      //     );

      //     contents.push(
      //       h("li", [
      //         numberNode(topic.comment_count),
      //         h(
      //           "h4",
      //           I18n.t(`comment_lowercase`, { count: topic.comment_count })
      //         )
      //       ])
      //     );

      //     contents.push(
      //       h("li.secondary", [
      //         numberNode(attrs.topicViews, { className: attrs.topicViewsHeat }),
      //         h("h4", I18n.t("views_lowercase", { count: attrs.topicViews }))
      //       ])
      //     );

      //     if (attrs.topicLikeCount) {
      //       contents.push(
      //         h("li.secondary", [
      //           numberNode(attrs.topicLikeCount),
      //           h("h4", I18n.t("likes_lowercase", { count: attrs.topicLikeCount }))
      //         ])
      //       );
      //     }

      //     if (attrs.topicLinkLength > 0) {
      //       contents.push(
      //         h("li.secondary", [
      //           numberNode(attrs.topicLinkLength),
      //           h("h4", I18n.t("links_lowercase", { count: attrs.topicLinkLength }))
      //         ])
      //       );
      //     }

      //     if (
      //       state.collapsed &&
      //       attrs.topicPostsCount > 2 &&
      //       attrs.participants.length > 0
      //     ) {
      //       const participants = renderParticipants.call(
      //         this,
      //         attrs.userFilters,
      //         attrs.participants.slice(0, 3)
      //       );
      //       contents.push(h("li.avatars", participants));
      //     }

      //     const nav = h(
      //       "nav.buttons",
      //       this.attach("button", {
      //         title: "topic.toggle_information",
      //         icon: state.collapsed ? "chevron-down" : "chevron-up",
      //         action: "toggleMap",
      //         className: "btn"
      //       })
      //     );

      //     return [nav, h("ul.clearfix", contents)];
      //   }
      // });
    });
  },
};

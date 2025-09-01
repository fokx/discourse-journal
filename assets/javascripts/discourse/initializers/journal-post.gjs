import { alias } from "@ember/object/computed";
import { withPluginApi } from "discourse/lib/plugin-api";
import PostsWithPlaceholders from "discourse/lib/posts-with-placeholders";
import JournalCommentButton from "../components/journal-comment-button";
import JournalShowComments from "../components/journal-show-comments";

const PLUGIN_ID = "discourse-journal";

export default {
  name: "journal-post",
  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");

    if (!siteSettings.journal_enabled) {
      return;
    }

    withPluginApi("1.34.0", (api) => {
      api.registerValueTransformer(
        "post-menu-buttons",
        ({
          value: dag,
          context: { post, buttonKeys, lastHiddenButtonKey },
        }) => {
          if (post.topic.details.can_create_post && post.journal) {
            dag.add("comment", JournalCommentButton, {
              after: lastHiddenButtonKey,
            });
            dag.delete(buttonKeys.REPLY);
          }
        }
      );

      api.renderAfterWrapperOutlet("post", JournalShowComments);

    });

    withPluginApi("0.8.12", (api) => {
      const store = api.container.lookup("service:store");

      api.addTrackedPostProperties(
        "journal",
        "reply_to_post_number",
        "comment",
        "showComment",
        "entry",
        "entry_post_id",
        "entry_post_ids"
      );

      api.registerValueTransformer("post-class", ({ value, context }) => {
        const { post } = context;
        if (post.journal && post.post_number !== 1) {
          if (post.comment) {
            const classes = ["comment"];
            if (post.showComment) {
              classes.push("show");
            }
            return [...value, ...classes];
          } else {
            return [...value, "entry"];
          }
        }
        return value;
      });

      // Post rendering modifications for journal posts
      api.registerValueTransformer("post-meta-data-infos", ({ value: metadata, context: { post, metaDataInfoKeys } }) => {
        if (post.journal) {
          if (post.entry) {
            // Remove reply-to username for entry posts
            metadata.delete(metaDataInfoKeys.REPLY_TO_TAB);
          }
          if (post.comment) {
            // Remove reply count for comment posts - this might need a different approach
            // as reply count is not in meta-data-infos
          }
        }
      });

      // The complex post-stream functionality below needs to remain for now
      // as it requires deep integration with post stream behavior that doesn't
      // have direct equivalents in the new Glimmer post stream yet

      // api.modifyClass("component:scrolling-post-stream", {
      //   pluginId: PLUGIN_ID,
      //
      //   showComments: [],
      //
      //   didInsertElement() {
      //     this._super(...arguments);
      //     this.appEvents.on("composer:opened", this, () => {
      //       const composer = api.container.lookup("service:composer");
      //       const post = composer.get("model.post");
      //
      //       if (post && post.entry) {
      //         this.set("showComments", [post.id]);
      //       }
      //
      //       this._refresh({ force: true });
      //     });
      //   },
      //
      //   buildArgs() {
      //     return Object.assign(
      //       this._super(...arguments),
      //       this.getProperties("showComments")
      //     );
      //   },
      // });

      // api.reopenWidget("post-stream", {
      //   buildKey: () => "post-stream",
      //
      //   firstPost() {
      //     return this.attrs.posts.toArray()[0];
      //   },
      //
      //   defaultState(attrs, state) {
      //     let defaultState = this._super(attrs, state);
      //
      //     const firstPost = this.firstPost();
      //     if (!firstPost || !firstPost.journal) {
      //       return defaultState;
      //     }
      //     defaultState["showComments"] = attrs.showComments;
      //
      //     return defaultState;
      //   },
      //
      //   showComments(entryId) {
      //     let showComments = this.state.showComments;
      //
      //     if (showComments.indexOf(entryId) === -1) {
      //       showComments.push(entryId);
      //       this.state.showComments = showComments;
      //       this.appEvents.trigger("post-stream:refresh", { force: true });
      //     }
      //   },
      //
      //   html(attrs, state) {
      //     const firstPost = this.firstPost();
      //     if (!firstPost || !firstPost.journal) {
      //       return this._super(...arguments);
      //     }
      //
      //     let showComments = state.showComments || [];
      //     if (attrs.showComments && attrs.showComments.length) {
      //       attrs.showComments.forEach((postId) => {
      //         if (!showComments.includes(postId)) {
      //           showComments.push(postId);
      //         }
      //       });
      //     }
      //
      //     let posts = attrs.posts || [];
      //     let postArray = this.capabilities.isAndroid ? posts : posts.toArray();
      //     let defaultComments = Number(siteSettings.journal_comments_default);
      //     let commentCount = 0;
      //     let lastVisible = null;
      //
      //     postArray.forEach((p, i) => {
      //       if (!p.topic) {
      //         return;
      //       }
      //
      //       if (p.comment) {
      //         commentCount++;
      //         let showingComments = showComments.indexOf(p.entry_post_id) > -1;
      //         let shownByDefault = commentCount <= defaultComments;
      //
      //         p["showComment"] = showingComments || shownByDefault;
      //         p["attachCommentToggle"] = false;
      //
      //         if (p["showComment"]) {
      //           lastVisible = i;
      //         }
      //
      //         if (
      //           (!postArray[i + 1] || postArray[i + 1].entry) &&
      //           !p["showComment"]
      //         ) {
      //           postArray[lastVisible]["attachCommentToggle"] = true;
      //           postArray[lastVisible]["hiddenComments"] =
      //             commentCount - defaultComments;
      //         }
      //       } else {
      //         p["attachCommentToggle"] = false;
      //
      //         commentCount = 0;
      //         lastVisible = i;
      //       }
      //     });
      //
      //     if (this.capabilities.isAndroid) {
      //       attrs.posts = postArray;
      //     } else {
      //       attrs.posts = PostsWithPlaceholders.create({
      //         posts: postArray,
      //         store,
      //       });
      //     }
      //
      //     return this._super(attrs, state);
      //   },
      // });

      api.modifyClass("model:post-stream", {
        pluginId: PLUGIN_ID,

        journal: alias("topic.journal"),

        getCommentIndex(post) {
          const posts = this.get("posts");
          let passed = false;
          let commentIndex = null;

          posts.some((p, i) => {
            if (passed && !p.reply_to_post_number) {
              commentIndex = i;
              return true;
            }
            if (
              p.post_number === post.reply_to_post_number &&
              i < posts.length - 1
            ) {
              passed = true;
            }
          });

          return commentIndex;
        },

        insertCommentInStream(post) {
          const stream = this.stream;
          const postId = post.get("id");
          const commentIndex = this.getCommentIndex(post) - 1;

          if (stream.indexOf(postId) > -1 && commentIndex && commentIndex > 0) {
            stream.removeObject(postId);
            stream.insertAt(commentIndex, postId);
          }
        },

        stagePost(post) {
          let result = this._super(...arguments);
          if (!this.journal) {
            return result;
          }

          if (post.get("reply_to_post_number")) {
            this.insertCommentInStream(post);
          }

          return result;
        },

        commitPost(post) {
          let result = this._super(...arguments);
          if (!this.journal) {
            return result;
          }

          if (post.get("reply_to_post_number")) {
            this.insertCommentInStream(post);
          }

          return result;
        },

        prependPost(post) {
          if (!this.journal) {
            return this._super(...arguments);
          }

          const stored = this.storePost(post);
          if (stored) {
            const posts = this.get("posts");

            if (post.post_number === 2 && posts[0].post_number === 1) {
              posts.insertAt(1, stored);
            } else {
              posts.unshiftObject(stored);
            }
          }

          return post;
        },

        appendPost(post) {
          if (!this.journal) {
            return this._super(...arguments);
          }

          const stored = this.storePost(post);
          if (stored) {
            const posts = this.get("posts");

            if (!posts.includes(stored)) {
              let insertPost = () => posts.pushObject(stored);

              if (post.get("reply_to_post_number")) {
                const commentIndex = this.getCommentIndex(post);

                if (commentIndex && commentIndex > 0) {
                  insertPost = () => posts.insertAt(commentIndex, stored);
                }
              }

              if (!this.get("loadingBelow")) {
                this.get("postsWithPlaceholders").appendPost(insertPost);
              } else {
                insertPost();
              }
            }

            if (stored.get("id") !== -1) {
              this.set("lastAppended", stored);
            }
          }

          return post;
        },
      });

      // Post avatar size is now handled by CSS classes from the post-class transformer
      // Comments get "comment" class, entries get "entry" class
      // CSS can target .post.comment .post-avatar for small size
      // and .post.entry .post-avatar for large size

      // Post rendering modifications for journal posts
      // This needs to be handled by transformers that modify post data
      api.registerValueTransformer("post-meta-data-infos", ({ value: metadata, context: { post, metaDataInfoKeys } }) => {
        if (post.journal) {
          if (post.entry) {
            // Remove reply-to username for entry posts
            metadata.delete(metaDataInfoKeys.REPLY_TO_TAB);
          }
          if (post.comment) {
            // Remove reply count for comment posts - this might need a different approach
            // as reply count is not in meta-data-infos
          }
        }
      });

      // Reply-to-tab click behavior for journal topics is now handled by CSS
      // The post-class transformer adds "entry" or "comment" classes
      // CSS can disable pointer-events on .post.comment .reply-to-tab or similar
    });
  },
};

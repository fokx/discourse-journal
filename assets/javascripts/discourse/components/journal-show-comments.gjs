import Component from "@glimmer/component";
import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
import { on } from "@ember/modifier";
import { i18n } from "discourse-i18n";

export default class JournalShowComments extends Component {
  static shouldRender(args) {
    return args.post && args.post.attachCommentToggle && args.post.hiddenComments > 0;
  }

  get showCommentsType() {
    const siteSettings = getOwner(this).lookup("service:site-settings");
    return Number(siteSettings.journal_comments_default) > 0 ? "more" : "all";
  }

  get showCommentsLabel() {
    return i18n(`topic.comment.show_comments.${this.showCommentsType}`, {
      count: this.args.post.hiddenComments,
    });
  }

  @action
  showComments(event) {
    event.preventDefault();

    // Trigger the showComments action with the entry post ID
    const appEvents = getOwner(this).lookup("service:app-events");
    appEvents.trigger("post-stream:refresh", { force: true });

    // Find the scrolling post stream component and call showComments
    const postStream = document.querySelector('.scrolling-post-stream');
    if (postStream && postStream._glimmerComponent) {
      postStream._glimmerComponent.showComments(this.args.post.entry_post_id);
    }
  }

  <template>
    <a
      href="#"
      class="show-comments"
      {{on "click" this.showComments}}
    >
      {{this.showCommentsLabel}}
    </a>
  </template>
}

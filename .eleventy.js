module.exports = function(config) {
  config.addLayoutAlias('archive-month', 'layouts/archive-month.liquid');
  config.addLayoutAlias('archive-year', 'layouts/archive-year.liquid');
  config.addLayoutAlias('content', 'layouts/content.liquid');
  config.addLayoutAlias('default', 'layouts/default.liquid');
  config.addLayoutAlias('discussion', 'layouts/discussion.liquid');
  config.addLayoutAlias('link', 'layouts/link.liquid');
  config.addLayoutAlias('note', 'layouts/note.liquid');
  config.addLayoutAlias('post', 'layouts/post.liquid');
  config.addLayoutAlias('presentation', 'layouts/presentation.liquid');
  config.addLayoutAlias('project', 'layouts/project.liquid');
  config.addLayoutAlias('talk', 'layouts/talk.liquid');

  config.addCollection('documents', function(collection) {
    return collection.getFilteredByGlob('**/*.md');
  });

  return {
    dir: {
      input: 'src',
      output: 'www'
    }
  };
};

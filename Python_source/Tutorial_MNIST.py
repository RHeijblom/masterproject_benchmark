# Import data
from tensorflow.examples.tutorials.mnist import input_data
mnist = input_data.read_data_sets("MNIST_data/", one_hot=True)

import tensorflow as tf
# MNIST images presented as 2D of floats
x = tf.placeholder(tf.float32, [None, 784])
# Weights (to be learned)
W = tf.Variable(tf.zeros([784, 10]))
# Bias (to be learned)
b = tf.Variable(tf.zeros([10]))
# Model
y = tf.nn.softmax(tf.matmul(x,W) + b)

# Expected output
y_ = tf.placeholder(tf.float32, [None, 10])
cross_entropy = tf.reduce_mean(-tf.reduce_sum(y_ * tf.log(y), reduction_indices=[1]))
# Objective
train_step = tf.train.GradientDescentOptimizer(0.5).minimize(cross_entropy)

# Init session
init = tf.initialize_all_variables()
sess = tf.Session()
sess.run(init)

# Train
for i in range(1000):
	batch_xs, batch_ys = mnist.train.next_batch(100)
	sess.run(train_step, feed_dict={x: batch_xs, y_: batch_ys})
	
# Evaluation 'model'
correct_prediction = tf.equal(tf.argmax(y,1), tf.argmax(y_,1))
accuracy = tf.reduce_mean(tf.cast(correct_prediction, tf.float32))

# Results
print(sess.run(accuracy, feed_dict={x: mnist.test.images, y_: mnist.test.labels}))
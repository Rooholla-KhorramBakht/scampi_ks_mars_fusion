FROM ros:noetic
SHELL ["/bin/bash", "-c"]

# Install required packages
RUN apt-get update && apt-get install -y cmake build-essential python3-pip libgtest-dev git ros-noetic-tf2-* git
RUN python3 -m pip install pyquaternion numpy==1.19 pyyaml catkin_pkg rospkg jupyter catkin_tools matplotlib scipy
RUN cd /root && git clone https://github.com/utiasSTARS/liegroups.git && cd liegroups && python3 -m pip install . && cd .. && rm -r liegroups

# Compile and Install Ceres
RUN apt-get install -y libgoogle-glog-dev libgflags-dev libatlas-base-dev libeigen3-dev libsuitesparse-dev 
RUN cd ~ && git clone https://ceres-solver.googlesource.com/ceres-solver && cd ceres-solver && git checkout 2.1.0 && \
 mkdir build && cd build && cmake .. && make -j$(nproc) && make install && cd ~ && rm -r ceres-solver

# Install manif
RUN cd ~ && git clone https://github.com/artivis/manif.git && cd manif && mkdir build && cd build && cmake .. && make -j$(nproc) && make install && cd ~ && rm -r manif

# Copy the project into the container
RUN mkdir -p /root/catkin_ws/src
COPY ./ /root/catkin_ws/src/scampi_ks_mars_fusion

# Install the solver
RUN cd /root/catkin_ws/src/scampi_ks_mars_fusion/solver && python3 -m pip install .

# Modify the mars_ros to add support for pose updates

RUN cd /root/catkin_ws/src/scampi_ks_mars_fusion/ros/pose_wrapper_scampi && \
    cp mars_pose.launch ../mars_ros/launch/mars_pose.launch && \
    cp mars_wrapper_pose.cpp ../mars_ros/src/mars_wrapper_pose.cpp && \
    cp mars_wrapper_pose.h ../mars_ros/include/mars_wrapper_pose.h && \
    cp pose_config.yaml ../mars_ros/launch/config/pose_config.yaml

# compile the package and source its installation script

RUN cd /root/catkin_ws/ && source /opt/ros/noetic/setup.bash && catkin build

RUN echo "source /root/scampi_ks_mars_fusion/devel/setup.bash" >> ~/.bashrc

CMD  jupyter notebook -y --no-browser --allow-root --ip='*' --NotebookApp.token='' --NotebookApp.password=''


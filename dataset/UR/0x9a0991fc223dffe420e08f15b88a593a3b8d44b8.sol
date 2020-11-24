 

pragma solidity ^0.4.19;
 
 

contract Danku_demo {
  function Danku_demo() public {
     
     
     
     
     
  }
  struct Submission {
      address payment_address;
       
      uint num_neurons_input_layer;
      uint num_neurons_output_layer;
       
      uint[] num_neurons_hidden_layer;
       
       
       
      int256[] weights;
      int256[] biases;
  }
  struct NeuralLayer {
    int256[] neurons;
    int256[] errors;
    string layer_type;
  }

  address public organizer;
   
  uint public best_submission_index;
   
  int256 public best_submission_accuracy = 0;
   
  int256 public model_accuracy_criteria;
   
  bool public use_test_data = false;
   
  uint constant partition_size = 25;
   
  uint constant datapoint_size = 3;
  uint constant prediction_size = 1;
   
   
  uint16 constant max_num_data_groups = 500;
   
  uint16 constant training_data_group_size = 400;
   
  uint16 constant testing_data_group_size = max_num_data_groups - training_data_group_size;
   
   
   
  bytes32[max_num_data_groups/partition_size] hashed_data_groups;
   
  uint[max_num_data_groups/partition_size] data_group_nonces;
   
   
  int256[datapoint_size][] public train_data;
  int256[datapoint_size][] public test_data;
  bytes32 partition_seed;
   
  uint public submission_stage_block_size = 241920;  
   
  uint public reveal_test_data_groups_block_size = 17280;  
   
  uint public evaluation_stage_block_size = 40320;  
  uint public init1_block_height;
  uint public init3_block_height;
  uint public init_level = 0;
   
   
  uint[training_data_group_size/partition_size] public training_partition;
  uint[testing_data_group_size/partition_size] public testing_partition;
  uint256 train_dg_revealed = 0;
  uint256 test_dg_revealed = 0;
  Submission[] submission_queue;
  bool public contract_terminated = false;
   
  int constant int_precision = 10000;

   
   
  function init1(bytes32[max_num_data_groups/partition_size] _hashed_data_groups, int accuracy_criteria, address organizer_refund_address) external {
     
    assert(contract_terminated == false);
     
    assert(init_level == 0);
    organizer = organizer_refund_address;
    init_level = 1;
    init1_block_height = block.number;

     
    assert(_hashed_data_groups.length == max_num_data_groups/partition_size);
    hashed_data_groups = _hashed_data_groups;
     
     
    assert(accuracy_criteria > 0);
    model_accuracy_criteria = accuracy_criteria;
  }

  function init2() external {
     
    assert(contract_terminated == false);
     
    assert(init_level == 1);
     
     
    if (block.number <= init1_block_height+20 && block.number > init1_block_height) {
       
       
      uint[] memory index_array = new uint[](max_num_data_groups/partition_size);
      for (uint i = 0; i < max_num_data_groups/partition_size; i++) {
        index_array[i] = i;
      }
      randomly_select_index(index_array);
      init_level = 2;
    } else {
       
       
      cancel_contract();
    }
  }

  function init3(int256[] _train_data_groups, int256 _train_data_group_nonces) external {
     
     
    assert(contract_terminated == false);
     
    assert(init_level == 2);
     
    assert((_train_data_groups.length/partition_size)/datapoint_size == 1);
     
     
     
    assert(sha_data_group(_train_data_groups, _train_data_group_nonces) ==
      hashed_data_groups[training_partition[train_dg_revealed]]);
    train_dg_revealed += 1;
     
    unpack_data_groups(_train_data_groups, true);
    if (train_dg_revealed == (training_data_group_size/partition_size)) {
      init_level = 3;
      init3_block_height = block.number;
    }
  }

  function get_training_index() public view returns(uint[training_data_group_size/partition_size]) {
    return training_partition;
  }

  function get_testing_index() public view returns(uint[testing_data_group_size/partition_size]) {
    return testing_partition;
  }

  function get_submission_queue_length() public view returns(uint) {
    return submission_queue.length;
  }

  function submit_model(
     
    address payment_address,
    uint num_neurons_input_layer,
    uint num_neurons_output_layer,
    uint[] num_neurons_hidden_layer,
    int[] weights,
    int256[] biases) public {
       
      assert(contract_terminated == false);
       
      assert(init_level == 3);
       
      assert(block.number < init3_block_height + submission_stage_block_size);
       
       
      assert(num_neurons_input_layer == datapoint_size - prediction_size);
       
       
      assert(num_neurons_output_layer == prediction_size || num_neurons_output_layer == (prediction_size+1));
       
      assert(valid_weights(weights, num_neurons_input_layer, num_neurons_output_layer, num_neurons_hidden_layer));
       
      submission_queue.push(Submission(
        payment_address,
        num_neurons_input_layer,
        num_neurons_output_layer,
        num_neurons_hidden_layer,
        weights,
        biases));
  }

  function get_submission_id(
     
    address paymentAddress,
    uint num_neurons_input_layer,
    uint num_neurons_output_layer,
    uint[] num_neurons_hidden_layer,
    int[] weights,
    int256[] biases) public view returns (uint) {
       
      for (uint i = 0; i < submission_queue.length; i++) {
        if (submission_queue[i].payment_address != paymentAddress) {
          continue;
        }
        if (submission_queue[i].num_neurons_input_layer != num_neurons_input_layer) {
          continue;
        }
        if (submission_queue[i].num_neurons_output_layer != num_neurons_output_layer) {
          continue;
        }
        for (uint j = 0; j < num_neurons_hidden_layer.length; j++) {
            if (submission_queue[i].num_neurons_hidden_layer[j] != num_neurons_hidden_layer[j]) {
              continue;
            }
        }
        for (uint k = 0; k < weights.length; k++) {
            if (submission_queue[i].weights[k] != weights[k]) {
              continue;
            }
        }
        for (uint l = 0; l < biases.length; l++) {
          if (submission_queue[i].biases[l] != biases[l]) {
            continue;
          }
        }
         
        return i;
      }
       
      require(false);
  }

    function reveal_test_data(int256[] _test_data_groups, int256 _test_data_group_nonces) external {
     
    assert(contract_terminated == false);
     
    assert(init_level == 3);
     
    assert(block.number >= init3_block_height + submission_stage_block_size);
     
    assert(block.number < init3_block_height + submission_stage_block_size + reveal_test_data_groups_block_size);
     
    assert((_test_data_groups.length/partition_size)/datapoint_size == 1);
     
    assert(sha_data_group(_test_data_groups, _test_data_group_nonces) ==
      hashed_data_groups[testing_partition[test_dg_revealed]]);
    test_dg_revealed += 1;
     
    unpack_data_groups(_test_data_groups, false);
     
    use_test_data = true;
  }

  function evaluate_model(uint submission_index) public {
     
     
     
    assert(contract_terminated == false);
     
    assert(init_level == 3);
     
    assert(block.number >= init3_block_height + submission_stage_block_size + reveal_test_data_groups_block_size);
     
    assert(block.number < init3_block_height + submission_stage_block_size + reveal_test_data_groups_block_size + evaluation_stage_block_size);
     
    int256 submission_accuracy = 0;
    if (use_test_data == true) {
      submission_accuracy = model_accuracy(submission_index, test_data);
    } else {
      submission_accuracy = model_accuracy(submission_index, train_data);
    }

     
    if (submission_accuracy > best_submission_accuracy) {
      best_submission_index = submission_index;
      best_submission_accuracy = submission_accuracy;
    }
  }

  function cancel_contract() public {
     
    assert(contract_terminated == false);
     
    assert(init_level < 3);
     
    organizer.transfer(this.balance);
     
    contract_terminated = true;
  }

  function finalize_contract() public {
     
    assert(contract_terminated == false);
     
    assert(init_level == 3);
     
    assert(block.number >= init3_block_height + submission_stage_block_size + reveal_test_data_groups_block_size + evaluation_stage_block_size);
     
    Submission memory best_submission = submission_queue[best_submission_index];
     
    if (best_submission_accuracy >= model_accuracy_criteria) {
      best_submission.payment_address.transfer(this.balance);
     
    } else {
      organizer.transfer(this.balance);
    }
    contract_terminated = true;
  }

  function model_accuracy(uint submission_index, int256[datapoint_size][] data) public constant returns (int256){
     
    assert(contract_terminated == false);
     
    assert(init_level == 3);
     
     
    Submission memory sub = submission_queue[submission_index];
    int256 true_prediction = 0;
    int256 false_prediction = 0;
    bool one_hot;  
    int[] memory prediction;
    int[] memory ground_truth;
    if ((prediction_size + 1) == sub.num_neurons_output_layer) {
      one_hot = true;
      prediction = new int[](sub.num_neurons_output_layer);
      ground_truth = new int[](sub.num_neurons_output_layer);
    } else {
      one_hot = false;
      prediction = new int[](prediction_size);
      ground_truth = new int[](prediction_size);
    }
    for (uint i = 0; i < data.length; i++) {
       
      for (uint j = datapoint_size-prediction_size; j < data[i].length; j++) {
        uint d_index = j - datapoint_size + prediction_size;
         
        if (one_hot == true) {
          if (data[i][j] == 0) {
            ground_truth[d_index] = 1;
            ground_truth[d_index + 1] = 0;
          } else if (data[i][j] == 1) {
            ground_truth[d_index] = 0;
            ground_truth[d_index + 1] = 1;
          } else {
             
            require(false);
          }
        } else {
          ground_truth[d_index] = data[i][j];
        }
      }
       
      prediction = get_prediction(sub, data[i]);
       
      for (uint k = 0; k < ground_truth.length; k++) {
        if (ground_truth[k] == prediction[k]) {
          true_prediction += 1;
        } else {
          false_prediction += 1;
        }
      }
    }
     
     
    return (true_prediction * int_precision) / (true_prediction + false_prediction);
  }

  function get_train_data_length() public view returns(uint256) {
    return train_data.length;
  }

  function get_test_data_length() public view returns(uint256) {
    return test_data.length;
  }

  function round_up_division(int256 dividend, int256 divisor) private pure returns(int256) {
     
    return (dividend + divisor -1) / divisor;
  }

  function not_in_train_partition(uint[training_data_group_size/partition_size] partition, uint number) private pure returns (bool) {
    for (uint i = 0; i < partition.length; i++) {
      if (number == partition[i]) {
        return false;
      }
    }
    return true;
  }

  function randomly_select_index(uint[] array) private {
    uint t_index = 0;
    uint array_length = array.length;
    uint block_i = 0;
     
    while(t_index < training_partition.length) {
      uint random_index = uint(sha256(block.blockhash(block.number-block_i))) % array_length;
      training_partition[t_index] = array[random_index];
      array[random_index] = array[array_length-1];
      array_length--;
      block_i++;
      t_index++;
    }
    t_index = 0;
    while(t_index < testing_partition.length) {
      testing_partition[t_index] = array[array_length-1];
      array_length--;
      t_index++;
    }
  }

  function valid_weights(int[] weights, uint num_neurons_input_layer, uint num_neurons_output_layer, uint[] num_neurons_hidden_layer) private pure returns (bool) {
     
     
    uint ns_total = 0;
    uint wa_total = 0;
    uint number_of_layers = 2 + num_neurons_hidden_layer.length;

    if (number_of_layers == 2) {
      ns_total = num_neurons_input_layer * num_neurons_output_layer;
    } else {
      for(uint i = 0; i < num_neurons_hidden_layer.length; i++) {
         
        if (i==0){
          ns_total += num_neurons_input_layer * num_neurons_hidden_layer[i];
         
        } else {
          ns_total += num_neurons_hidden_layer[i-1] * num_neurons_hidden_layer[i];
        }
      }
       
      ns_total += num_neurons_hidden_layer[num_neurons_hidden_layer.length-1] * num_neurons_output_layer;
    }
     
    wa_total = weights.length;

    return ns_total == wa_total;
  }

    function unpack_data_groups(int256[] _data_groups, bool is_train_data) private {
    int256[datapoint_size][] memory merged_data_group = new int256[datapoint_size][](_data_groups.length/datapoint_size);

    for (uint i = 0; i < _data_groups.length/datapoint_size; i++) {
      for (uint j = 0; j < datapoint_size; j++) {
        merged_data_group[i][j] = _data_groups[i*datapoint_size + j];
      }
    }
    if (is_train_data == true) {
       
      for (uint k = 0; k < merged_data_group.length; k++) {
        train_data.push(merged_data_group[k]);
      }
    } else {
       
      for (uint l = 0; l < merged_data_group.length; l++) {
        test_data.push(merged_data_group[l]);
      }
    }
  }

    function sha_data_group(int256[] data_group, int256 data_group_nonce) private pure returns (bytes32) {
       
       
       
      uint index_tracker = 0;
      uint256 total_size = datapoint_size * partition_size;
       
      int256[] memory all_data_points = new int256[](total_size+1);

      for (uint256 i = 0; i < total_size; i++) {
        all_data_points[index_tracker] = data_group[i];
        index_tracker += 1;
      }
       
      all_data_points[index_tracker] = data_group_nonce;
       
      return sha256(all_data_points);
    }

  function relu_activation(int256 x) private pure returns (int256) {
    if (x < 0) {
      return 0;
    } else {
      return x;
    }
  }

  function get_layer(uint nn) private pure returns (int256[]) {
    int256[] memory input_layer = new int256[](nn);
    return input_layer;
  }

  function get_hidden_layers(uint[] l_nn) private pure returns (int256[]) {
    uint total_nn = 0;
     
    for (uint i = 1; i < l_nn.length-1; i++) {
      total_nn += l_nn[i];
    }
    int256[] memory hidden_layers = new int256[](total_nn);
    return hidden_layers;
  }

  function access_hidden_layer(int256[] hls, uint[] l_nn, uint index) private pure returns (int256[]) {
     
     
    int256[] memory hidden_layer = new int256[](l_nn[index+1]);
    uint hidden_layer_index = 0;
    uint start = 0;
    uint end = 0;
    for (uint i = 0; i < index; i++) {
      start += l_nn[i+1];
    }
    for (uint j = 0; j < (index + 1); j++) {
      end += l_nn[j+1];
    }
    for (uint h_i = start; h_i < end; h_i++) {
      hidden_layer[hidden_layer_index] = hls[h_i];
      hidden_layer_index += 1;
    }
    return hidden_layer;
  }

  function get_prediction(Submission sub, int[datapoint_size] data_point) private pure returns(int256[]) {
    uint[] memory l_nn = new uint[](sub.num_neurons_hidden_layer.length + 2);
    l_nn[0] = sub.num_neurons_input_layer;
    for (uint i = 0; i < sub.num_neurons_hidden_layer.length; i++) {
      l_nn[i+1] = sub.num_neurons_hidden_layer[i];
    }
    l_nn[sub.num_neurons_hidden_layer.length+1] = sub.num_neurons_output_layer;
    return forward_pass(data_point, sub.weights, sub.biases, l_nn);
  }

  function forward_pass(int[datapoint_size] data_point, int256[] weights, int256[] biases, uint[] l_nn) private pure returns (int256[]) {
     
    int256[] memory input_layer = get_layer(l_nn[0]);
    int256[] memory hidden_layers = get_hidden_layers(l_nn);
    int256[] memory output_layer = get_layer(l_nn[l_nn.length-1]);

     
    for (uint input_i = 0; input_i < l_nn[0]; input_i++) {
      input_layer[input_i] = data_point[input_i];
    }
    return forward_pass2(l_nn, input_layer, hidden_layers, output_layer, weights, biases);
  }

  function forward_pass2(uint[] l_nn, int256[] input_layer, int256[] hidden_layers, int256[] output_layer, int256[] weights, int256[] biases) public pure returns (int256[]) {
     
     
    uint[] memory index_counter = new uint[](2);
    for (uint layer_i = 0; layer_i < (l_nn.length-1); layer_i++) {
      int256[] memory current_layer;
      int256[] memory prev_layer;
       
      if (hidden_layers.length != 0) {
        if (layer_i == 0) {
          current_layer = access_hidden_layer(hidden_layers, l_nn, layer_i);
          prev_layer = input_layer;
         
        } else if (layer_i == (l_nn.length-2)) {
          current_layer = output_layer;
          prev_layer = access_hidden_layer(hidden_layers, l_nn, (layer_i-1));
         
        } else {
          current_layer = access_hidden_layer(hidden_layers, l_nn, layer_i);
          prev_layer = access_hidden_layer(hidden_layers, l_nn, layer_i-1);
        }
      } else {
        current_layer = output_layer;
        prev_layer = input_layer;
      }
      for (uint layer_neuron_i = 0; layer_neuron_i < current_layer.length; layer_neuron_i++) {
        int total = 0;
        for (uint prev_layer_neuron_i = 0; prev_layer_neuron_i < prev_layer.length; prev_layer_neuron_i++) {
          total += prev_layer[prev_layer_neuron_i] * weights[index_counter[0]];
          index_counter[0]++;
        }
        total += biases[layer_i];
        total = total / int_precision;  
         
        if (layer_i == (l_nn.length-2)) {
            output_layer[layer_neuron_i] = relu_activation(total);
        } else {
            hidden_layers[index_counter[1]] = relu_activation(total);
        }
        index_counter[1]++;
      }
    }
    return output_layer;
  }

   
  function () public payable {}
}
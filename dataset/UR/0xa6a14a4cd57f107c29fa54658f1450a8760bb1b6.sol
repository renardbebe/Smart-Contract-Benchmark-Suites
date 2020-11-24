 

pragma solidity >=0.4.21 <0.6.0;

contract MultiSig{

  struct invoke_status{
    uint propose_height;
    bytes32 invoke_hash;
    string func_name;
    uint64 invoke_id;
    bool called;
    address[] invoke_signers;
    bool processing;
    bool exists;
  }

  uint public signer_number;
  address[] public signers;
  address public owner;
  mapping (bytes32 => invoke_status) public invokes;
  mapping (bytes32 => uint64) public used_invoke_ids;
  mapping(address => uint) public signer_join_height;

  event signers_reformed(address[] old_signers, address[] new_signers);
  event valid_function_sign(string name, uint64 id, uint64 current_signed_number, uint propose_height);
  event function_called(string name, uint64 id, uint propose_height);

  modifier enough_signers(address[] memory s){
    require(s.length >=3, "the number of signers must be >=3");
    _;
  }
  constructor(address[] memory s) public enough_signers(s){
    signers = s;
    signer_number = s.length;
    owner = msg.sender;
    for(uint i = 0; i < s.length; i++){
      signer_join_height[s[i]] = block.number;
    }
  }

  modifier only_signer{
    require(array_exist(signers, msg.sender), "only a signer can call this");
    _;
  }

  function get_majority_number() private view returns(uint){
    return signer_number/2 + 1;
  }

  function array_exist (address[] memory accounts, address p) private pure returns (bool){
    for (uint i = 0; i< accounts.length;i++){
      if (accounts[i]==p){
        return true;
      }
    }
    return false;
  }

  function is_all_minus_sig(uint number, uint64 id, string memory name, bytes32 hash, address sender) internal only_signer returns (bool){
    bytes32 b = keccak256(abi.encodePacked(name));
    require(id <= used_invoke_ids[b] + 1, "you're using a too big id.");

    if(id > used_invoke_ids[b]){
      used_invoke_ids[b] = id;
    }

    if(!invokes[hash].exists){
      invokes[hash].propose_height = block.number;
      invokes[hash].invoke_hash = hash;
      invokes[hash].func_name= name;
      invokes[hash].invoke_id= id;
      invokes[hash].called= false;
      invokes[hash].invoke_signers.push(sender);
      invokes[hash].processing= false;
      invokes[hash].exists= true;
      emit valid_function_sign(name, id, 1, block.number);
      return false;
    }

    invoke_status storage invoke = invokes[hash];
    require(!array_exist(invoke.invoke_signers, sender), "you already called this method");

    uint valid_invoke_num = 0;
    uint join_height = signer_join_height[msg.sender];
    for(uint i = 0; i < invoke.invoke_signers.length; i++){
      require(join_height < invoke.propose_height, "this proposal is already exist before you become a signer");
      if(array_exist(signers, invoke.invoke_signers[i])){
        valid_invoke_num ++;
      }
    }
    invoke.invoke_signers.push(msg.sender);
    valid_invoke_num ++;
    emit valid_function_sign(name, id, uint64(valid_invoke_num), invoke.propose_height);
    if(invoke.called) return false;
    if(valid_invoke_num < signer_number-number) return false;
    invoke.processing = true;
    return true;
  }

  modifier is_majority_sig(uint64 id, string memory name) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sig, msg.data));
    if(!is_all_minus_sig(get_majority_number()-1, id, name, hash, msg.sender))
      return ;
    set_called(hash);
    _;
  }

  modifier is_all_sig(uint64 id, string memory name) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sig, msg.data));
    if(!is_all_minus_sig(0, id, name, hash, msg.sender)) return ;
    set_called(hash);
    _;
  }

  function set_called(bytes32 hash) internal only_signer{
    invoke_status storage invoke = invokes[hash];
    require(invoke.exists, "no such function");
    require(!invoke.called, "already called");
    require(invoke.processing, "cannot call this separately");
    invoke.called = true;
    invoke.processing = false;
    emit function_called(invoke.func_name, invoke.invoke_id, invoke.propose_height);
  }

  function reform_signers(uint64 id, address[] calldata s)
    external
    only_signer
    enough_signers(s)
    is_majority_sig(id, "reform_signers"){
    address[] memory old_signers = signers;
    for(uint i = 0; i < s.length; i++){
      if(array_exist(old_signers, s[i])){
      }else{
        signer_join_height[s[i]] = block.number;
      }
    }
    for(uint i = 0; i < old_signers.length; i++){
      if(array_exist(s, old_signers[i])){
      }else{
        signer_join_height[old_signers[i]] = 0;
      }
    }
    signer_number = s.length;
    signers = s;
    emit signers_reformed(old_signers, signers);
  }

  function get_unused_invoke_id(string memory name) public view returns(uint64){
    return used_invoke_ids[keccak256(abi.encodePacked(name))] + 1;
  }
  function get_signers() public view returns(address[] memory){
    return signers;
  }
}

contract ERC20TokenBankInterface{
  function transfer(uint64 id, address to, uint tokens) external returns(bool success);
  function balance() public view returns(uint);
  function token() public view returns(address, string memory);
}

contract TokenBankFactoryInterface{
  function newTokenBank(string memory name, address token_contract, address[] memory s) public returns(ERC20TokenBankInterface);
}

contract ERC20TokenBankProvider is MultiSig{
  mapping (bytes32 => address) public supported_token_factories;
  mapping (bytes32 => uint) public created_token_numbers;
  uint public total_created_token_numbers;

  string[] public supported_token_factory_names;

  event token_bank_created(string name, ERC20TokenBankInterface addr);
  event add_token_factory(string name, address factory);

  constructor(address[] memory s) MultiSig(s) public{}

  function addTokenFactory(uint64 id, string memory factory_name, address factory)
    public
    only_signer
    is_majority_sig(id, "addTokenFactory"){
      bytes32 b = keccak256(abi.encodePacked(factory_name));
      require(factory!=address(0));
      supported_token_factories[b] = factory;
      supported_token_factory_names.push(factory_name);
      emit add_token_factory(factory_name, factory);
    }

  function newTokenBank(string memory name, address token_contract, string memory factory_name, address[] memory s) public returns(ERC20TokenBankInterface){

      bytes32 b = keccak256(abi.encodePacked(factory_name));
      address a = supported_token_factories[b];
      require(a != address(0), "not supported factory name");
      TokenBankFactoryInterface tbfi = TokenBankFactoryInterface(a);
      ERC20TokenBankInterface addr = tbfi.newTokenBank(name, token_contract, s);
      created_token_numbers[b] = created_token_numbers[b] + 1;
      total_created_token_numbers = total_created_token_numbers + 1;
      emit token_bank_created(name, addr);
      return addr;
  }
}
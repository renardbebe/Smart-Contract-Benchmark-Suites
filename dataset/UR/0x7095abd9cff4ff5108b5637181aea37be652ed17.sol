 

pragma solidity >=0.4.21 <0.6.0;

contract MultiSigInterface{
  function update_and_check_reach_majority(uint64 id, string memory name, bytes32 hash, address sender) public returns (bool);
  function is_signer(address addr) public view returns(bool);
}

contract MultiSigTools{
  MultiSigInterface public multisig_contract;
  constructor(address _contract) public{
    require(_contract!= address(0x0));
    multisig_contract = MultiSigInterface(_contract);
  }

  modifier only_signer{
    require(multisig_contract.is_signer(msg.sender), "only a signer can call in MultiSigTools");
    _;
  }

  modifier is_majority_sig(uint64 id, string memory name) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sig, msg.data));
    if(multisig_contract.update_and_check_reach_majority(id, name, hash, msg.sender)){
      _;
    }
  }

  event TransferMultiSig(address _old, address _new);

  function transfer_multisig(uint64 id, address _contract) public only_signer
  is_majority_sig(id, "transfer_multisig"){
    require(_contract != address(0x0));
    address old = address(multisig_contract);
    multisig_contract = MultiSigInterface(_contract);
    emit TransferMultiSig(old, _contract);
  }
}


library AddressArray{
  function exists(address[] storage self, address addr) public view returns(bool){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return true;
      }
    }
    return false;
  }

  function index_of(address[] storage self, address addr) public view returns(uint){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return i;
      }
    }
    require(false, "AddressArray:index_of, not exist");
  }

  function remove(address[] storage self, address addr) public returns(bool){
    uint index = index_of(self, addr);
    self[index] = self[self.length - 1];

    delete self[self.length-1];
    self.length--;
  }

  function replace(address[] storage self, address old_addr, address new_addr) public returns(bool){
    uint index = index_of(self, old_addr);
    self[index] = new_addr;
  }
}

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

contract ERC20TokenBankInterface{
  function balance() public view returns(uint);
  function token() public view returns(address, string memory);
  function issue(address _to, uint _amount) public returns (bool success);
}

contract ERC20Salary is MultiSigTools{
  using SafeMath for uint;
  using AddressArray for address[];

  struct employee_info{
    uint salary;
    uint period;
    uint total;
    uint claimed;
    uint last_block_num;
    uint pause_block_num;
    address leader;
    bool paused;
    bool exists;
  }

  ERC20TokenBankInterface public erc20bank;
  string public token_name;
  address[] public employee_accounts;
  mapping (address => employee_info) public employee_infos;
  address public owner;
  bool public is_admin_mode;

  event ClaimedSalary(address account, address to, uint amount);

  constructor(string memory _name, address _owner, address _erc20bank, address _multisig) MultiSigTools(_multisig) public{
    token_name = _name;
    erc20bank = ERC20TokenBankInterface(_erc20bank);
    owner = _owner;
    is_admin_mode = true;
  }

  function change_token_bank(uint64 id, address _addr) public  only_signer is_majority_sig(id, "change_token_bank"){
    require(_addr != address(0x0), "invalid address");
    erc20bank = ERC20TokenBankInterface(_addr);
  }

  function balance() public view returns(uint){
    return erc20bank.balance();
  }

  function token() public view returns(address, string memory){
    return erc20bank.token();
  }

  function unclaimed_amount() public returns(uint){
    uint total = 0;
    for(uint i = 0; i < employee_accounts.length; ++i){
      _update_salary(employee_accounts[i]);
      uint t = employee_infos[employee_accounts[i]].total.safeSub(employee_infos[employee_accounts[i]].claimed);
      total = total.safeAdd(t);
    }
    return total;
  }

  function admin_init_employee(address account, uint last_block_num, uint pause_block_num,
                               uint period, uint salary, uint total, uint claimed, address leader) public returns(bool){
    require(owner == msg.sender, "not owner");
    require(is_admin_mode, "not admin mode");
    _primitive_init_employee(account, last_block_num, pause_block_num, false, period, salary, total, claimed, leader);
    return true;
  }

  function admin_remove_employee(address account) public returns(bool){
    require(owner == msg.sender, "not owner");
    require(is_admin_mode, "not admin mode");
    _remove_employee(account);
    return true;
  }

  function stop_admin_mode() public{
    require(owner == msg.sender, "not owner");
    is_admin_mode = false;
  }

  function add_employee(uint64 id, address account, uint last_block_num, uint period, uint salary, address leader)
    public only_signer
    is_majority_sig(id, "add_employee")
    returns(bool)
    {
      require(!is_admin_mode, "still in admin init mode");
      require(account != address(0));
      require(last_block_num >0);
      require(period > 0);
      require(salary > 0);
      require(leader != account, "cannot be self leader");
      if(employee_infos[account].exists) return false;
      _primitive_init_employee(account, last_block_num, 0, false, period, salary, 0, 0, leader);

      return true;
    }

    function add_employee_with_meta(uint64 id, address account, uint last_block_num,
                                    uint pause_block_num, bool paused, uint period,
                                    uint salary, uint total, uint claimed, address leader)
    public only_signer
    is_majority_sig(id, "add_employee_with_meta")
    returns(bool)
                                    {
      require(!is_admin_mode, "still in admin init mode");
      _primitive_init_employee(account, last_block_num, pause_block_num, paused, period, salary, total, claimed, leader);
      return true;
    }

    function _primitive_init_employee( address account, uint last_block_num,
                                     uint pause_block_num, bool paused, uint period,
                                     uint salary, uint total, uint claimed, address leader) internal{
      if(!employee_infos[account].exists) {
        employee_accounts.push(account);
      }

      employee_infos[account].salary = salary;
      employee_infos[account].period = period;
      employee_infos[account].total = total;
      employee_infos[account].claimed = claimed;
      employee_infos[account].last_block_num = last_block_num;
      employee_infos[account].pause_block_num = pause_block_num;
      employee_infos[account].leader = leader;
      employee_infos[account].paused = paused;
      employee_infos[account].exists = true;
    }

    function remove_employee(uint64 id, address account) public only_signer is_majority_sig(id, "remove_employee"){
      _remove_employee(account);
    }

    function _remove_employee(address account) internal returns(bool){
      if(!employee_infos[account].exists) return false;
      employee_accounts.remove(account);
      delete employee_infos[account];
      return true;
    }

    function change_employee_period(uint64 id, address account, uint period) public only_signer is_majority_sig(id, "change_employee_period"){
      require(employee_infos[account].exists);
      _update_salary(account);
      employee_infos[account].period = period;
    }

    function change_employee_salary(uint64 id, address account, uint salary) public only_signer is_majority_sig(id, "change_employee_salary"){
      require(employee_infos[account].exists);
      _update_salary(account);
      employee_infos[account].salary= salary;
    }

    function change_employee_leader(uint64 id, address account, address leader) public only_signer is_majority_sig(id, "change_employee_leader"){
      require(employee_infos[account].exists);
      require(account != leader, "account cannot be self leader");
      _update_salary(account);
      employee_infos[account].leader = leader;
    }

    function change_employee_status(uint64 id, address account, bool pause) public only_signer is_majority_sig(id, "change_employee_status"){
      require(employee_infos[account].exists);
      require(employee_infos[account].paused != pause, "status already done");
      _update_salary(account);
      _change_employee_status(account, pause);
    }

    function _change_employee_status(address account, bool pause) internal {
      employee_infos[account].paused = pause;
      employee_infos[account].pause_block_num = (block.number - employee_infos[account].pause_block_num);
    }

    function change_subordinate_period(address account, uint period) public {
      require(employee_infos[account].exists);
      require(employee_infos[account].leader == msg.sender, "not your subordinate");
      _update_salary(account);
      employee_infos[account].period = period;
    }
    function change_subordinate_salary(address account, uint salary) public {
      require(employee_infos[account].exists);
      require(employee_infos[account].leader == msg.sender, "not your subordinate");
      _update_salary(account);
      employee_infos[account].salary = salary;
    }
    function change_subordinate_status(address account, bool pause) public {
      require(employee_infos[account].exists);
      require(employee_infos[account].leader == msg.sender, "not your subordinate");
      _update_salary(account);
      _change_employee_status(account, pause);
    }

    function _update_salary(address account) private {
      employee_info storage ei = employee_infos[account];
      if(ei.paused) return ;
      uint t = block.number.safeSub(ei.pause_block_num);
      t = t.safeSub(ei.last_block_num);

      uint p = t.safeDiv(ei.period);
      if(p == 0) return ;
      ei.total = ei.total.safeAdd(p.safeMul(ei.salary));
      ei.last_block_num = ei.last_block_num.safeAdd(p.safeMul(ei.period));
    }

    function update_salary(address account) public{
      require(employee_infos[account].exists, "not exist");
      _update_salary(account);
    }

    function self_info() public returns(uint salary, uint period, uint total,
                                       uint claimed, uint last_claim_block_num, uint paused_block_num, bool paused, address leader){
      require(employee_infos[msg.sender].exists, "not exist");
      _update_salary(msg.sender);
      return get_employee_info_with_account(msg.sender);
    }

    function claim_salary(address to, uint amount) public returns(bool){
      require(employee_infos[msg.sender].exists);
      _update_salary(msg.sender);
      employee_info storage ei = employee_infos[msg.sender];
      require(ei.total.safeSub(ei.claimed) >= amount);
      require(amount <= balance());
      ei.claimed  = ei.claimed.safeAdd(amount);
      erc20bank.issue(to, amount);
      emit ClaimedSalary(msg.sender, to, amount);
      return true;
    }

    function get_employee_count() public view returns(uint){
      return employee_accounts.length;
    }

    function get_employee_info_with_index(uint index) public view returns(uint salary, uint period, uint total, uint claimed, uint last_claim_block_num, uint paused_block_num, bool paused, address leader){
      require(index >= 0 && index < employee_accounts.length);
      address account = employee_accounts[index];
      require(employee_infos[account].exists);
      return get_employee_info_with_account(account);
    }

    function get_employee_info_with_account(address account) public view returns(uint salary, uint period, uint total,
                                                                                 uint claimed, uint last_claim_block_num, uint paused_block_num, bool paused, address leader){
      require(employee_infos[account].exists);
      salary = employee_infos[account].salary;
      period = employee_infos[account].period;
      total = employee_infos[account].total;
      claimed = employee_infos[account].claimed;
      last_claim_block_num = employee_infos[account].last_block_num;
      leader = employee_infos[account].leader;
      paused = employee_infos[account].paused;
      paused_block_num = employee_infos[account].pause_block_num;
    }
}
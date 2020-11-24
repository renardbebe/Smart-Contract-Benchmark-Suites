 

pragma solidity ^0.4.18;
 
 
 
 
 
 
 
 

 
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
 
 
contract ERC20Interface {
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 

contract VitaToken is ERC20Interface, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    address public manager;
    address public reward_contract;
    uint public crowd_start_date;
    uint public crowd_end_date;
    uint public first_bonus_duration;
    uint public second_bonus_duration;
    uint public extra_bonus_duration;
     
    uint public first_bonus_amount;
    uint public second_bonus_amount;
    uint public third_bonus_amount;
    uint public extra_bonus_amount;
    uint public ETH_VTA;
    uint public total_reward_amount;
    uint public max_crowd_vitas;
    uint public collected_crowd_vitas;
     
    uint public collected_crowd_wei;

    mapping(address => uint) balances;
    mapping(address => uint) rewards;
    mapping(address => mapping(address => uint)) allowed;
    function VitaToken() public {
        symbol = "VTA";
        name = "Vita Token";
         
         
         
         
        decimals = 18;
        ETH_VTA = 100000;
         
        collected_crowd_wei = 0;
         
        max_crowd_vitas = 3 * 10 ** 27;
         
        collected_crowd_vitas = 0;
         
        totalSupply = 10 ** 28;
        manager = msg.sender;
         
        total_reward_amount = totalSupply / 2;
        balances[manager] = totalSupply / 2;

        crowd_start_date = now;
        extra_bonus_duration = 4 days;
         
        crowd_end_date = crowd_start_date + extra_bonus_duration + 122 days;
         
        first_bonus_duration = 47 days;
         
        second_bonus_duration = 30 days;
         


        extra_bonus_amount = 40000;
        first_bonus_amount = 35000;
        second_bonus_amount = 20000;
        third_bonus_amount = 10000;
    }

    modifier restricted(){
        require(msg.sender == manager);
        _;
    }

     
    modifier onlyVitaReward(){
        require(msg.sender == reward_contract);
        _;
    }
     
    function transferOwnership(address new_manager) public restricted {
        emit OwnershipTransferred(manager, new_manager);
        manager = new_manager;
    }

     
    function newVitaReward(address new_reward_contract) public restricted {
        uint amount_to_transfer;
        if(reward_contract == address(0)){
            amount_to_transfer = total_reward_amount;
        }else{
            amount_to_transfer = balances[reward_contract];
        }
        balances[new_reward_contract] = amount_to_transfer;
        balances[reward_contract] = 0;
        reward_contract = new_reward_contract;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function rewardsOf(address _owner) public view returns (uint balance) {
        return rewards[_owner];
    }

     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
    function reward(address patient, address company, uint tokens_patient, uint tokens_company, uint tokens_vita_team) public onlyVitaReward returns (bool success) {
        balances[reward_contract] = safeSub(balances[reward_contract], (tokens_patient + tokens_company + tokens_vita_team));
         
        balances[patient] = safeAdd(balances[patient], tokens_patient);
         
        balances[company] = safeAdd(balances[company], tokens_company);
         
        balances[manager] = safeAdd(balances[manager], tokens_vita_team);
        rewards[patient] = safeAdd(rewards[patient], 1);
        emit Transfer(reward_contract, patient, tokens_patient);
        emit Transfer(reward_contract, company, tokens_company);
        emit Transfer(reward_contract, manager, tokens_vita_team);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(balances[from] >= tokens && allowed[from][msg.sender] >= tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function () public payable {
        require(now >= crowd_start_date && now <= crowd_end_date);
        require(collected_crowd_vitas < max_crowd_vitas);
        uint tokens;
        if(now <= crowd_start_date + extra_bonus_duration){
            tokens = msg.value * (ETH_VTA + extra_bonus_amount);
        }else if(now <= crowd_start_date + extra_bonus_duration + first_bonus_duration){
            tokens = msg.value * (ETH_VTA + first_bonus_amount);
        }else if(now <= crowd_start_date + extra_bonus_duration + first_bonus_duration + second_bonus_duration){
            tokens = msg.value * (ETH_VTA + second_bonus_amount);
        }else{
            tokens = msg.value * (ETH_VTA + third_bonus_amount);
        }

        balances[manager] = safeSub(balances[manager], tokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        emit Transfer(manager, msg.sender, tokens);
        collected_crowd_wei += msg.value;
        collected_crowd_vitas += tokens;
        manager.transfer(msg.value);
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}
 

pragma solidity 0.5.4;


interface Token {

     
    function totalSupply() external view returns (uint256 supply);

     
     
    function balanceOf(address _owner) external view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) external returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) external returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function decimals() external view returns (uint8 decimals);
}

 
 
 
contract Utils {
    enum MessageTypeId {
        None,
        BalanceProof,
        BalanceProofUpdate,
        Withdraw,
        CooperativeSettle,
        IOU,
        MSReward
    }

     
     
     
     
    function contractExists(address contract_address) public view returns (bool) {
        uint size;

        assembly {
            size := extcodesize(contract_address)
        }

        return size > 0;
    }
}

contract UserDeposit is Utils {
    uint constant public withdraw_delay = 100;   

     
    Token public token;

     
    address public msc_address;
    address public one_to_n_address;

     
     
    mapping(address => uint256) public total_deposit;
     
    mapping(address => uint256) public balances;
    mapping(address => WithdrawPlan) public withdraw_plans;

     
    uint256 public whole_balance = 0;
     
    uint256 public whole_balance_limit;

     
    struct WithdrawPlan {
        uint256 amount;
        uint256 withdraw_block;   
    }

     

    event BalanceReduced(address indexed owner, uint newBalance);
    event WithdrawPlanned(address indexed withdrawer, uint plannedBalance);

     

    modifier canTransfer() {
        require(msg.sender == msc_address || msg.sender == one_to_n_address, "unknown caller");
        _;
    }

     

     
     
    constructor(address _token_address, uint256 _whole_balance_limit)
        public
    {
         
        require(_token_address != address(0x0), "token at address zero");
        require(contractExists(_token_address), "token has no code");
        token = Token(_token_address);
        require(token.totalSupply() > 0, "token has no total supply");  
         
        require(_whole_balance_limit > 0, "whole balance limit is zero");
        whole_balance_limit = _whole_balance_limit;
    }

     
     
     
     
    function init(address _msc_address, address _one_to_n_address)
        external
    {
         
        require(msc_address == address(0x0) && one_to_n_address == address(0x0), "already initialized");

         
        require(_msc_address != address(0x0), "MS contract at address zero");
        require(contractExists(_msc_address), "MS contract has no code");
        msc_address = _msc_address;

         
        require(_one_to_n_address != address(0x0), "OneToN at address zero");
        require(contractExists(_one_to_n_address), "OneToN has no code");
        one_to_n_address = _one_to_n_address;
    }

     
     
     
     
     
     
     
    function deposit(address beneficiary, uint256 new_total_deposit)
        external
    {
        require(new_total_deposit > total_deposit[beneficiary], "deposit not increasing");

         
        uint256 added_deposit = new_total_deposit - total_deposit[beneficiary];

        balances[beneficiary] += added_deposit;
        total_deposit[beneficiary] += added_deposit;

         
        require(whole_balance + added_deposit >= whole_balance, "overflowing deposit");
        whole_balance += added_deposit;

         
        require(whole_balance <= whole_balance_limit, "too much deposit");

         
        require(token.transferFrom(msg.sender, address(this), added_deposit), "tokens didn't transfer");
    }

     
     
     
     
     
     
    function transfer(
        address sender,
        address receiver,
        uint256 amount
    )
        canTransfer()
        external
        returns (bool success)
    {
        require(sender != receiver, "sender == receiver");
        if (balances[sender] >= amount && amount > 0) {
            balances[sender] -= amount;
            balances[receiver] += amount;
            emit BalanceReduced(sender, balances[sender]);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
    function planWithdraw(uint256 amount)
        external
    {
        require(amount > 0, "withdrawing zero");
        require(balances[msg.sender] >= amount, "withdrawing too much");

        withdraw_plans[msg.sender] = WithdrawPlan({
            amount: amount,
            withdraw_block: block.number + withdraw_delay
        });
        emit WithdrawPlanned(msg.sender, balances[msg.sender] - amount);
    }

     
     
     
     
     
     
    function withdraw(uint256 amount)
        external
    {
        WithdrawPlan storage withdraw_plan = withdraw_plans[msg.sender];
        require(amount <= withdraw_plan.amount, "withdrawing more than planned");
        require(withdraw_plan.withdraw_block <= block.number, "withdrawing too early");
        uint256 withdrawable = min(amount, balances[msg.sender]);
        balances[msg.sender] -= withdrawable;

         
        require(whole_balance - withdrawable <= whole_balance, "underflow in whole_balance");
        whole_balance -= withdrawable;

        emit BalanceReduced(msg.sender, balances[msg.sender]);
        delete withdraw_plans[msg.sender];

        require(token.transfer(msg.sender, withdrawable), "tokens didn't transfer");
    }

     
     
     
    function effectiveBalance(address owner)
        external
        view
        returns (uint256 remaining_balance)
    {
        WithdrawPlan storage withdraw_plan = withdraw_plans[owner];
        if (withdraw_plan.amount > balances[owner]) {
            return 0;
        }
        return balances[owner] - withdraw_plan.amount;
    }

    function min(uint256 a, uint256 b) pure internal returns (uint256)
    {
        return a > b ? b : a;
    }
}


 

 

 
 
 
 
 
 

 
 

 
 
 
 
 
 
 
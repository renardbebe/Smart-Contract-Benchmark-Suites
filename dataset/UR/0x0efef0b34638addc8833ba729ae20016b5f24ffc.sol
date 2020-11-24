 

 
pragma solidity ^0.4.15;


 
contract ERC20 {
  
     
    function totalSupply() public constant returns (uint256 supply);

     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}
 
pragma solidity ^0.4.15;


 
 
 
 
 
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

     
    function Owned() {
        owner = msg.sender;
    }

     
     
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

     
     
    function changeOwnership(address _newOwner) onlyOwner {
        require(_newOwner != 0x0);

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

     
     
     
    function proposeOwnership(address _newOwnerCandidate) onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

     
     
    function acceptOwnership() {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

     
     
    function removeOwnership(address _dac) onlyOwner {
        require(_dac == 0xdac);
        owner = 0x0;
        newOwnerCandidate = 0x0;
        OwnershipRemoved();     
    }

} 

 
 

pragma solidity ^0.4.15;





 
 
 
 
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;
    mapping (address=>bool) private escapeBlacklist;

     
     
     
     
     
     
     
     
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

    modifier onlyEscapeHatchCallerOrOwner {
        require ((msg.sender == escapeHatchCaller)||(msg.sender == owner));
        _;
    }

     
     
     
    function blacklistEscapeToken(address _token) internal {
        escapeBlacklist[_token] = true;
        EscapeHatchBlackistedToken(_token);
    }

    function isTokenEscapable(address _token) constant public returns (bool) {
        return !escapeBlacklist[_token];
    }

     
     
     
    function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {   
        require(escapeBlacklist[_token]==false);

        uint256 balance;

        if (_token == 0x0) {
            balance = this.balance;
            escapeHatchDestination.transfer(balance);
            EscapeHatchCalled(_token, balance);
            return;
        }

        ERC20 token = ERC20(_token);
        balance = token.balanceOf(this);
        token.transfer(escapeHatchDestination, balance);
        EscapeHatchCalled(_token, balance);
    }

     
     
     
     
     
    function changeHatchEscapeCaller(address _newEscapeHatchCaller) onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchBlackistedToken(address token);
    event EscapeHatchCalled(address token, uint amount);
}

 
pragma solidity ^0.4.18;
 


 
 
contract MiniMeToken {
    function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint);
    function totalSupplyAt(uint _blockNumber) public constant returns(uint);
}




 
 
 
 
 
contract WithdrawContract is Escapable {

     
    struct Deposit {
        uint block;     
        ERC20 token;    
        uint amount;    
        bool canceled;  
    }

    Deposit[] public deposits;  
    MiniMeToken rewardToken;      

    mapping (address => uint) public nextDepositToPayout;  
    mapping (address => mapping(uint => bool)) skipDeposits;

 
 
 

     
     
     
     
     
     
     
     
     
     
     
    function WithdrawContract(
        MiniMeToken _rewardToken,
        address _escapeHatchCaller,
        address _escapeHatchDestination)
        Escapable(_escapeHatchCaller, _escapeHatchDestination)
        public
    {
        rewardToken = _rewardToken;
    }

     
    function () payable public {
        newEtherDeposit(0);
    }
 
 
 

     
     
     
     
     
     
     
    function newEtherDeposit(uint _block)
        public onlyOwner payable
        returns (uint _idDeposit)
    {
        require(msg.value>0);
        require(_block < block.number);
        _idDeposit = deposits.length ++;

         
        Deposit storage d = deposits[_idDeposit];
        d.block = _block == 0 ? block.number -1 : _block;
        d.token = ERC20(0);
        d.amount = msg.value;
        NewDeposit(_idDeposit, ERC20(0), msg.value);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
    function newTokenDeposit(ERC20 _token, uint _amount, uint _block)
        public onlyOwner
        returns (uint _idDeposit)
    {
        require(_amount > 0);
        require(_block < block.number);

         
        require( _token.transferFrom(msg.sender, address(this), _amount) );
        _idDeposit = deposits.length ++;

         
        Deposit storage d = deposits[_idDeposit];
        d.block = _block == 0 ? block.number -1 : _block;
        d.token = _token;
        d.amount = _amount;
        NewDeposit(_idDeposit, _token, _amount);
    }

     
     
     
     
    function cancelPaymentGlobally(uint _idDeposit) public onlyOwner {
        require(_idDeposit < deposits.length);
        deposits[_idDeposit].canceled = true;
        CancelPaymentGlobally(_idDeposit);
    }

 
 
 
     
     
     
     
     
    function withdraw() public {
        uint acc = 0;  
        uint i = nextDepositToPayout[msg.sender];  
        require(i<deposits.length);
        ERC20 currentToken = deposits[i].token;  

        require(msg.gas>149000);  
        while (( i< deposits.length) && ( msg.gas > 148000)) {
            Deposit storage d = deposits[i];

             
            if ((!d.canceled)&&(!isDepositSkiped(msg.sender, i))) {

                 
                 
                 
                if (currentToken != d.token) {
                    nextDepositToPayout[msg.sender] = i;
                    require(doPayment(i-1, msg.sender, currentToken, acc));
                    assert(nextDepositToPayout[msg.sender] == i);
                    currentToken = d.token;
                    acc =0;
                }

                 
                acc +=  d.amount *
                        rewardToken.balanceOfAt(msg.sender, d.block) /
                            rewardToken.totalSupplyAt(d.block);
            }

            i++;  
        }
         
        nextDepositToPayout[msg.sender] = i;
        require(doPayment(i-1, msg.sender, currentToken, acc));
        assert(nextDepositToPayout[msg.sender] == i);
    }

     
     
     
     
     
     
    function skipPayment(uint _idDeposit, bool _skip) public {
        require(_idDeposit < deposits.length);
        skipDeposits[msg.sender][_idDeposit] = _skip;
        SkipPayment(_idDeposit, _skip);
    }

 
 
 

     
     
     
     
     
     
    function getPendingReward(ERC20 _token, address _holder) public constant returns(uint) {
        uint acc =0;
        for (uint i=nextDepositToPayout[msg.sender]; i<deposits.length; i++) {
            Deposit storage d = deposits[i];
            if ((d.token == _token)&&(!d.canceled) && (!isDepositSkiped(_holder, i))) {
                acc +=  d.amount *
                    rewardToken.balanceOfAt(_holder, d.block) /
                        rewardToken.totalSupplyAt(d.block);
            }
        }
        return acc;
    }

     
     
     
    function canWithdraw(address _holder) public constant returns (bool) {
        if (nextDepositToPayout[_holder] == deposits.length) return false;
        for (uint i=nextDepositToPayout[msg.sender]; i<deposits.length; i++) {
            Deposit storage d = deposits[i];
            if ((!d.canceled) && (!isDepositSkiped(_holder, i))) {
                uint amount =  d.amount *
                    rewardToken.balanceOfAt(_holder, d.block) /
                        rewardToken.totalSupplyAt(d.block);
                if (amount>0) return true;
            }
        }
        return false;
    }

     
     
    function nDeposits() public constant returns (uint) {
        return deposits.length;
    }

     
     
     
     
    function isDepositSkiped(address _holder, uint _idDeposit) public constant returns(bool) {
        return skipDeposits[_holder][_idDeposit];
    }

 
 
 

     
     
     
     
     
     
     
     
    function doPayment(uint _idDeposit,  address _dest, ERC20 _token, uint _amount) internal returns (bool) {
        if (_amount == 0) return true;
        if (address(_token) == 0) {
            if (!_dest.send(_amount)) return false;    
        } else {
            if (!_token.transfer(_dest, _amount)) return false;
        }
        Withdraw(_idDeposit, _dest, _token, _amount);
        return true;
    }

    function getBalance(ERC20 _token, address _holder) internal constant returns (uint) {
        if (address(_token) == 0) {
            return _holder.balance;
        } else {
            return _token.balanceOf(_holder);
        }
    }

 
 
 

    event Withdraw(uint indexed lastIdPayment, address indexed holder, ERC20 indexed tokenContract, uint amount);
    event NewDeposit(uint indexed idDeposit, ERC20 indexed tokenContract, uint amount);
    event CancelPaymentGlobally(uint indexed idDeposit);
    event SkipPayment(uint indexed idDeposit, bool skip);
}
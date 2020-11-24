 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed burner, uint256 value);
}

 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

 
 
contract Owned {
    
    struct Investor {
        address sender;
        uint amount;
        bool kyced;
    }
    
     
    string public version = "1.10";
    
    address public owner;
    address public newOwner;
     
    address public rewardPoolWallet;
    
     
    Investor[] public investors;
    
    mapping(address => uint) public mapInvestors;
    mapping(address => bool) public founders;
    
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event TranferETH(address indexed _to, uint amount);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
     
    function changeKYCStatus(address inv, bool kycStatus) onlyOwner public returns (bool success) {
        require(kycStatus == !investors[mapInvestors[inv]-1].kyced);
        investors[mapInvestors[inv]-1].kyced = kycStatus;
        return true;
    }
    
    function setRewardPoolWallet(address rewardWallet) onlyOwner public returns(bool success) {
        rewardPoolWallet = rewardWallet;
        return true;
    }
    
    function isExistInvestor(address inv) public constant returns (bool exist) {
        return mapInvestors[inv] != 0;
    }
    
    function isExistFounder(address _founder) public constant returns (bool exist) {
        return founders[_founder];
    }
    
    function removeFounder(address _founder) onlyOwner public returns (bool success) {
        require(founders[_founder]);
        founders[_founder] = false;
        return true;
    }
    
    function addFounder(address _founder) onlyOwner public returns (bool success) {
        require(!founders[_founder]);
        founders[_founder] = true;
        return true;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
 
 
 
contract ELOVEToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;
    
    uint minInvest = 0.5 ether;
    uint maxInvest = 500 ether;
    
    uint softcap = 5000 ether;
    uint hardcap = 40000 ether;

    uint public icoStartDate;
    
    uint[4] public roundEnd;
    uint[4] public roundTokenLeft;
    uint[4] public roundBonus;
    
    uint public tokenLockTime;
    uint public tokenFounderLockTime;
    bool icoEnded = false;
    bool kycCompleted = false;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    uint etherExRate = 2000;

     
     
     
    function ELOVEToken(string tName, string tSymbol) public {
        symbol = tSymbol;
        name = tName;
        decimals = 2;
        _totalSupply = 200000000 * 10**uint(decimals);  
        
        icoStartDate            = 1518566401;    
        
         
         
         
         
         
        roundEnd = [1519862400, 1521158400, 1523836800, 1525132800];
        roundTokenLeft = [1000000000, 1000000000, 3000000000, 3000000000];
        roundBonus = [40, 30, 10, 0];
        
         
        tokenFounderLockTime = roundEnd[3] + 365*24*3600;
        
         
        tokenLockTime = 1572566400;      
        
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }

    function setRoundEnd(uint round, uint newTime) onlyOwner public returns (bool success)  {
        require(now<newTime);
        if (round>0) {
            require(newTime>roundEnd[round-1]);
        } else {
            require(newTime<roundEnd[1]);
        }

        roundEnd[round] = newTime;
         
        if (round == 3) {
            tokenFounderLockTime = newTime + 365*24*3600;
        }
        return true;
    }
    
     
    function refundNonKYCInvestor() onlyOwner public returns (bool success) {
        require(!kycCompleted);
        for(uint i = 0; i<investors.length; i++) {
            if (!investors[i].kyced) {
                investors[i].sender.transfer(investors[i].amount);    
                investors[i].amount = 0;
            }
        }
        kycCompleted = true;
        return true;
    }
    
    function setSoftCap(uint newSoftCap) onlyOwner public returns (bool success) {
        softcap = newSoftCap;
        return true;
    }
    
    function setEthExRate(uint newExRate) onlyOwner public returns (bool success) {
        etherExRate = newExRate;
        return true;
    }
    
    function setICOStartTime(uint newTime) onlyOwner public returns (bool success) {
        icoStartDate = newTime;
        return true;
    }
    
    function setLockTime(uint newLockTime) onlyOwner public returns (bool success) {
        require(now<newLockTime);
        tokenLockTime = newLockTime;
        return true;
    }

     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
    }

     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    
     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        require(icoEnded);
         
        require(now<tokenLockTime);
         
         
         
        require((founders[msg.sender] && now>tokenFounderLockTime) || (!founders[msg.sender] && (msg.sender == rewardPoolWallet || mapInvestors[msg.sender] == 0 || investors[mapInvestors[msg.sender]-1].kyced)));
         
        require(msg.sender == owner || to != 0x0);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(icoEnded);
         
         
         
        require((founders[from] && now>tokenFounderLockTime) || (!founders[from] && (from == rewardPoolWallet || investors[mapInvestors[from]-1].kyced)));
        
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    function processRound(uint round) internal {
         
        require(roundTokenLeft[round]>0);
         
        var tokenCanBeBought = (msg.value*10**uint(decimals)*etherExRate*(100+roundBonus[round])).div(100*10**18);
        if (tokenCanBeBought<roundTokenLeft[round]) {
            balances[owner] = balances[owner] - tokenCanBeBought;
            balances[msg.sender] = balances[msg.sender] + tokenCanBeBought;
            roundTokenLeft[round] = roundTokenLeft[round]-tokenCanBeBought;
            
            Transfer(owner, msg.sender, tokenCanBeBought);
            
            if (mapInvestors[msg.sender] > 0) {
                 
                investors[mapInvestors[msg.sender]-1].amount += msg.value;
            } else {
                uint ind = investors.push(Investor(msg.sender, msg.value, false));                
                mapInvestors[msg.sender] = ind;
            }
        } else {
            var neededEtherToBuy = (10**18*roundTokenLeft[round]*100).div(10**uint(decimals)).div(etherExRate*(100+roundBonus[round]));
            balances[owner] = balances[owner] - roundTokenLeft[round];
            balances[msg.sender] = balances[msg.sender] + roundTokenLeft[round];
            roundTokenLeft[round] = 0;
            
            Transfer(owner, msg.sender, roundTokenLeft[round]);
            
            if (mapInvestors[msg.sender] > 0) {
                 
                investors[mapInvestors[msg.sender]-1].amount += neededEtherToBuy;
            } else {
                uint index = investors.push(Investor(msg.sender, neededEtherToBuy, false));  
                mapInvestors[msg.sender] = index;
            }
            
             
            msg.sender.transfer(msg.value-neededEtherToBuy);
        }
    }

     
     
     
    function () public payable {
        require(!icoEnded);
        uint currentTime = now;
        require (currentTime>icoStartDate);
        require (msg.value>= minInvest && msg.value<=maxInvest);
        
        if (currentTime<roundEnd[0]) {
            processRound(0);
        } else if (currentTime<roundEnd[1]) {
            processRound(1);
        } else if (currentTime<roundEnd[2]) {
            processRound(2);
        } else if (currentTime<roundEnd[3]) {
            processRound(3);
        } else {
             
            if (this.balance<softcap) {
                 
                for(uint i = 0; i<investors.length; i++) {
                    investors[i].sender.transfer(investors[i].amount);
                    TranferETH(investors[i].sender, investors[i].amount);
                }
            } else {
                 
                require(rewardPoolWallet != address(0));
                uint sumToBurn = roundTokenLeft[0] + roundTokenLeft[1] + roundTokenLeft[2] + roundTokenLeft[3];
                balances[owner] = balances[owner] - sumToBurn;
                balances[rewardPoolWallet] += sumToBurn;
                
                Transfer(owner, rewardPoolWallet, sumToBurn);
                
                roundTokenLeft[0] = roundTokenLeft[1] = roundTokenLeft[2] = roundTokenLeft[3] = 0;
            }
            
             
            msg.sender.transfer(msg.value);
            TranferETH(msg.sender, msg.value);
            icoEnded = true;
        }
    }
    
    function withdrawEtherToOwner() onlyOwner public {   
        require(now>roundEnd[3] && this.balance>softcap);
        owner.transfer(this.balance);
        TranferETH(owner, this.balance);
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
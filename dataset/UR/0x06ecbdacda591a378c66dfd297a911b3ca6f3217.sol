 

pragma solidity ^0.4.15;

contract Owned {

     
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

     
     
     
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20Basic {
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address who) public constant returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Distribute is Owned {

    mapping (address => uint) public tokensOwed;
    ERC20Basic token;

    event AmountSet(address contributor, uint amount);
    event AmountSent(address contributor, uint amount);

    function Distribute(address _token) public {
        token = ERC20Basic(_token);
    }

    function setAmount(address[] contributors, uint[] amounts) public onlyOwner {
        for (uint256 i = 0; i < contributors.length; i++) {
            tokensOwed[contributors[i]] = amounts[i];
        }
    }

    function withdrawAllTokens() public onlyOwner {
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function() public payable {
        collect();
    }

    function collect() public {
        uint amount = tokensOwed[msg.sender];
        require(amount > 0);
        tokensOwed[msg.sender] = 0;
        token.transfer(msg.sender, amount);
        AmountSent(msg.sender, amount);
    }

    function withdrawOnBehalf(address beneficiary) public {
        uint amount = tokensOwed[beneficiary];
        require(amount > 0);
        tokensOwed[beneficiary] = 0;
        token.transfer(beneficiary, amount);
        AmountSent(beneficiary, amount);
    }

    function multiWithdraw(address[] beneficiaries) public {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            withdrawOnBehalf(beneficiaries[i]);
        }
    }
}
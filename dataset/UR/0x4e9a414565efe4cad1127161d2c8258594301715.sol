 

pragma solidity ^0.4.24;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns(address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


 
contract AzbitTokenInterface is IERC20 {

    function releaseDate() external view returns (uint256);

}


 
contract AzbitAirdrop is Ownable {

     

     
    AzbitTokenInterface public azbitToken;


     

     
    constructor(
        address tokenAddress
    ) 
        public 
    {
        _setToken(tokenAddress);
    }


     

     
    function sendTokens(
        address beneficiary,
        uint256 amount
    )
        external
        onlyOwner
    {
        _sendTokens(beneficiary, amount);
    }

     
    function sendTokensArray(
        address[] beneficiaries, 
        uint256[] amounts
    )
        external
        onlyOwner
    {
        require(beneficiaries.length == amounts.length, "array lengths have to be equal");
        require(beneficiaries.length > 0, "array lengths have to be greater than zero");

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            _sendTokens(beneficiaries[i], amounts[i]);
        }
    }


     

     
    function contractTokenBalance()
        public 
        view 
        returns(uint256) 
    {
        return azbitToken.balanceOf(this);
    }


     

     
    function _setToken(address tokenAddress) 
        internal 
    {
        azbitToken = AzbitTokenInterface(tokenAddress);
        require(contractTokenBalance() >= 0, "The token being added is not ERC20 token");
    }

     
    function _sendTokens(
        address beneficiary, 
        uint256 amount
    )
        internal
    {
        require(beneficiary != address(0), "Address cannot be 0x0");
        require(amount > 0, "Amount cannot be zero");
        require(amount <= contractTokenBalance(), "not enough tokens on this contract");

         
        require(azbitToken.transfer(beneficiary, amount), "tokens are not transferred");
    }
}
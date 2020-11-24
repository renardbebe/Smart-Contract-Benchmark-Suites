 

 

pragma solidity ^0.5.2;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
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

 

pragma solidity ^0.5.2;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

pragma solidity ^0.5.2;


 
interface ERC20 {
    function totalSupply() external view returns (uint supply);

    function balanceOf(address _owner) external view returns (uint balance);

    function transfer(address _to, uint _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint _value) external returns (bool success);

    function approve(address _spender, uint _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint remaining);

    function decimals() external view returns (uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 

pragma solidity ^0.5.2;



 
interface KyberNetworkProxyInterface {
    function maxGasPrice() external view returns (uint);

    function getUserCapInWei(address user) external view returns (uint);

    function getUserCapInTokenWei(address user, ERC20 token) external view returns (uint);

    function enabled() external view returns (bool);

    function info(bytes32 id) external view returns (uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes calldata hint) external payable returns (uint);
}

 

pragma solidity ^0.5.2;





contract KyberConverter is Ownable {
    using SafeMath for uint256;
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    KyberNetworkProxyInterface public kyberNetworkProxyContract;
    address public walletId;

    ERC20 public stableToken;

     
    event Swap(address indexed sender, ERC20 srcToken, ERC20 destToken);

     
    function() external payable {
    }

    constructor (KyberNetworkProxyInterface _kyberNetworkProxyContract, address _walletId, address _stableAddress) public {
        kyberNetworkProxyContract = _kyberNetworkProxyContract;
        walletId = _walletId;
        stableToken = ERC20(_stableAddress);
    }

    function setStableToken(address _stableAddress) public onlyOwner {
        stableToken = ERC20(_stableAddress);
    }

    function getStableToken() public view returns (address) {
        return address(stableToken);
    }

     
    function getConversionRates(
        ERC20 srcToken,
        uint srcQty,
        ERC20 destToken
    ) public
    view
    returns (uint, uint)
    {
        return kyberNetworkProxyContract.getExpectedRate(srcToken, destToken, srcQty);

    }

     
    function executeSwapAndDonate(
        ERC20 srcToken,
        uint srcQty,
        uint maxDestAmount,
        IDonationCommunity community
    ) public {
        uint minConversionRate;

         
        uint256 prevSrcBalance = srcToken.balanceOf(address(this));

         
        require(srcToken.transferFrom(msg.sender, address(this), srcQty));

         
         
        require(srcToken.approve(address(kyberNetworkProxyContract), 0));

         
        require(srcToken.approve(address(kyberNetworkProxyContract), srcQty));

         
        (minConversionRate,) = kyberNetworkProxyContract.getExpectedRate(srcToken, ETH_TOKEN_ADDRESS, srcQty);

         
        bytes memory hint;
        uint256 amount = kyberNetworkProxyContract.tradeWithHint(
            srcToken,
            srcQty,
            ETH_TOKEN_ADDRESS,
            address(this),
            maxDestAmount,
            minConversionRate,
            walletId,
            hint
        );

         
        require(
            srcToken.approve(address(kyberNetworkProxyContract), 0),
            "Could not clear approval of kyber to use srcToken on behalf of this contract"
        );

         
        uint256 change = srcToken.balanceOf(address(this)).sub(prevSrcBalance);

        if (change > 0) {
            require(
                srcToken.transfer(msg.sender, change),
                "Could not transfer change to sender"
            );
        }

         
        community.donateDelegated.value(amount)(msg.sender);


         
        emit Swap(msg.sender, srcToken, ETH_TOKEN_ADDRESS);
    }

    function executeSwapMyETHToStable(
    ) public payable returns (uint256) {
        uint minConversionRate;
        uint srcQty = msg.value;
        address destAddress = msg.sender;

         
        (minConversionRate,) = kyberNetworkProxyContract.getExpectedRate(ETH_TOKEN_ADDRESS, stableToken, srcQty);

        uint maxDestAmount = srcQty.mul(minConversionRate).mul(105).div(100);
         

         
        bytes memory hint;
        uint256 amount = kyberNetworkProxyContract.tradeWithHint.value(srcQty)(
            ETH_TOKEN_ADDRESS,
            srcQty,
            stableToken,
            destAddress,
            maxDestAmount,
            minConversionRate,
            walletId,
            hint
        );
         
        emit Swap(msg.sender, ETH_TOKEN_ADDRESS, stableToken);

        return amount;
    }

     
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient funds to withdraw");
        msg.sender.transfer(address(this).balance);
    }

}

interface IDonationCommunity {

    function donateDelegated(address payable _donator) external payable;
}
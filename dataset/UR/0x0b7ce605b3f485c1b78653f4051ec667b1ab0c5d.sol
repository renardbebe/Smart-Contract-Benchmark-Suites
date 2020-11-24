 

pragma solidity ^0.5.7;

interface CTokenInterface {
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);  
    function borrowBalanceCurrent(address account) external returns (uint);

    function balanceOf(address owner) external view returns (uint256 balance);
    function transferFrom(address, address, uint) external returns (bool);
    function underlying() external view returns (address);
}

interface CETHInterface {
    function repayBorrowBehalf(address borrower) external payable;  
}

interface ERC20Interface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function getAssetsIn(address account) external view returns (address[] memory);
}

interface PoolInterface {
    function accessToken(address[] calldata ctknAddr, uint[] calldata tknAmt, bool isCompound) external;
    function paybackToken(address[] calldata ctknAddr, bool isCompound) external payable;
}


contract DSMath {

    function sub(uint x, uint y) internal pure returns (uint z) {
        z = x - y <= x ? x - y : 0;
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}


contract Helpers is DSMath {

    address public comptrollerAddr = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    address payable public liquidityAddr = 0x5Ab9de08725D3344b745888c65FfdDe06B6e6b36;

    address public cEthAddr = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

     
    function enterMarket(address[] memory cErc20) internal {
        ComptrollerInterface troller = ComptrollerInterface(comptrollerAddr);
        address[] memory markets = troller.getAssetsIn(address(this));
        address[] memory toEnter;
        for (uint j = 0; j < cErc20.length; j++) {
            bool isEntered = false;
            for (uint i = 0; i < markets.length; i++) {
                if (markets[i] == cErc20[j]) {
                    isEntered = true;
                    break;
                }
            }
            if (!isEntered) {
                toEnter[toEnter.length] = cErc20[j];
            }
        }
        troller.enterMarkets(toEnter);
    }

     
    function enteredMarkets(address owner) internal view returns (address[] memory) {
        address[] memory markets = ComptrollerInterface(comptrollerAddr).getAssetsIn(owner);
        return markets;
    }

     
    function setApproval(address erc20, uint srcAmt, address to) internal {
        ERC20Interface erc20Contract = ERC20Interface(erc20);
        uint tokenAllowance = erc20Contract.allowance(address(this), to);
        if (srcAmt > tokenAllowance) {
            erc20Contract.approve(to, uint(-1));
        }
    }

}


contract ImportResolver is Helpers {
    event LogCompoundImport(address owner, uint percentage, bool isCompound, address[] markets, address[] borrowAddr, uint[] borrowAmt);

    function importAssets(uint toConvert, bool isCompound) external {
        uint initialBal = sub(liquidityAddr.balance, 10000000000);  
        address[] memory markets = enteredMarkets(msg.sender);
        address[] memory borrowAddr;
        uint[] memory borrowAmt;

         
        for (uint i = 0; i < markets.length; i++) {
            address cErc20 = markets[i];
            uint toPayback = CTokenInterface(cErc20).borrowBalanceCurrent(msg.sender);
            toPayback = wmul(toPayback, toConvert);
            if (toPayback > 0) {
                borrowAddr[borrowAddr.length] = cErc20;
                borrowAmt[borrowAmt.length] = toPayback;
            }
        }

         
         

         
         
         
         
         
         
         
         
         
         
         
         
         

         
         
         
         
         
         
         
         
         
         

         
         
         
         
         
         
         
         
         
         
         
         
         
         

         
         
         

        emit LogCompoundImport(
            msg.sender,
            toConvert,
            isCompound,
            markets,
            borrowAddr,
            borrowAmt
        );
    }

}


contract CompImport is ImportResolver {
    function() external payable {}
}
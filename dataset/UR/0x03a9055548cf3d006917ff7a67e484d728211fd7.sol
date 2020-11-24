 

pragma solidity 0.4.25;


 
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

 
import "./Approves.sol";
import "./Upgradeable.sol";
import "./IOpportunityManager.sol";
import "./IPositionManager.sol";
import "./IFeeModel.sol";
import "./IOracle.sol";
import "./INAVCalculator.sol";
import "./IRAYToken.sol";
import "./IStorageWrapper.sol";
import "./IStorage.sol";



  
  
  
  
  
  
  
  
  
  
  
  
  
  

contract PortfolioManager is IERC721Receiver, Upgradeable, Approves {
    using SafeMath
    for uint256;


     

     


     
    bytes32 internal constant RAY_TOKEN_CONTRACT = keccak256("RAYTokenContract");
    bytes32 internal constant FEE_MODEL_CONTRACT = keccak256("FeeModelContract");
    bytes32 internal constant ADMIN_CONTRACT = keccak256("AdminContract");
    bytes32 internal constant POSITION_MANAGER_CONTRACT = keccak256("PositionManagerContract");
    bytes32 internal constant STORAGE_WRAPPER_TWO_CONTRACT = keccak256("StorageWrapperTwoContract");
    bytes32 internal constant NAV_CALCULATOR_CONTRACT = keccak256("NAVCalculatorContract");
    bytes32 internal constant OPPORTUNITY_MANAGER_CONTRACT = keccak256("OpportunityManagerContract");
    bytes32 internal constant ORACLE_CONTRACT = keccak256("OracleContract");

     
    bytes32 internal constant name = keccak256("RAY");

    IStorage public _storage;
    bool public deprecated;


     


    event LogPurchaseRAYT(
        bytes32 indexed tokenId,
        bytes32 indexed portfolioKey,
        address indexed beneficiary,
        uint value
    );

    event LogPurchaseOpportunityToken(
      bytes32 tokenId,
      bytes32 indexed portfolioKey
    );

    event LogWithdrawFromRAYT(
      bytes32 indexed tokenId,
      uint value,
      uint tokenValue  
    );

    event LogBurnRAYT(
        bytes32 indexed tokenId,
        address indexed beneficiary,
        uint value,
        uint tokenValue  
    );

    event LogDepositToRAYT(
        bytes32 indexed tokenId,
        uint value,
        uint tokenValue  
    );


     


     
    modifier existingRAYT(bytes32 tokenId)
    {
        require(
             IRAYToken(_storage.getContractAddress(RAY_TOKEN_CONTRACT)).tokenExists(tokenId),
            "#PortfolioMananger existingRAYT Modifier: This is not a valid RAYT"
        );

        _;
    }


     
    modifier onlyOracle()
    {

      require(
        _storage.getContractAddress(ORACLE_CONTRACT) == msg.sender,
        "#NCController onlyOracle Modifier: Only Oracle can call this"
      );

      _;

    }


     
    modifier onlyAdmin()
    {

      require(
        _storage.getContractAddress(ADMIN_CONTRACT) == msg.sender,
        "#NCController onlyAdmin Modifier: Only Admin can call this"
      );

      _;

    }


     
     
     
    modifier onlyGovernance()
    {
        require(
            msg.sender == _storage.getGovernanceWallet(),
            "#PortfolioMananger onlyGovernance Modifier: Only Governance can call this"
        );

        _;
    }


     
     
     
     
    modifier isValidOpportunity(bytes32 key, bytes32 opportunityKey)
    {

      require(_storage.isValidOpportunity(key, opportunityKey),
      "#PortfolioMananger isValidOpportunity modifier: This is not a valid opportunity for this portfolio");

        _;
    }


     
     
     
     
     
     
    modifier isCorrectAddress(bytes32 opportunityKey, address opportunity)
    {

      require(_storage.getVerifier(opportunityKey) == opportunity,
      "#PortfolioMananger isCorrectAddress modifier: This is not the correct address for this opportunity");

        _;
    }


     
     
     
     
    modifier isValidPortfolio(bytes32 key)
    {

      require(_storage.getVerifier(key) != address(0),
      "#PortfolioMananger isValidPortfolio modifier: This is not a valid portfolio");

        _;
    }


     
    modifier notDeprecated()
    {
        require(
             deprecated == false,
            "#PortfolioMananger notDeprecated Modifier: In deprecated mode - this contract has been deprecated"
        );

        _;
    }


     

     


     
     
     
    constructor(
      address __storage
    )
        public
    {

      _storage = IStorage(__storage);

    }


     
     
     
    function() external payable {

    }



     


     
     
     
     
     
     
     
     
     
     
    function mint(
      bytes32 key,
      address beneficiary,
      uint value
    )
      external
      notDeprecated
      isValidPortfolio(key)
      payable
      returns(bytes32)
    {

        notPaused(key);
        verifyValue(key, msg.sender, value);  
        uint pricePerShare = INAVCalculator(_storage.getContractAddress(NAV_CALCULATOR_CONTRACT)).getPortfolioPricePerShare(key);

         
        bytes32 tokenId = IPositionManager(_storage.getContractAddress(POSITION_MANAGER_CONTRACT)).createToken(
            key,
            _storage.getContractAddress(RAY_TOKEN_CONTRACT),
            beneficiary,
            value,
            pricePerShare
        );

         
        IStorageWrapper(_storage.getContractAddress(STORAGE_WRAPPER_TWO_CONTRACT)).setTokenKey(tokenId, key);

         
        uint cumulativeRate = IFeeModel(_storage.getContractAddress(FEE_MODEL_CONTRACT)).updateCumulativeRate(_storage.getPrincipalAddress(key));
          
        IStorageWrapper(_storage.getContractAddress(STORAGE_WRAPPER_TWO_CONTRACT)).setEntryRate(key, tokenId, cumulativeRate);
         
        IStorageWrapper(_storage.getContractAddress(STORAGE_WRAPPER_TWO_CONTRACT)).setAvailableCapital(key, _storage.getAvailableCapital(key) + value);

        emit LogPurchaseRAYT(tokenId, key, beneficiary, value);

        return tokenId;

    }


     
     
     
     
     
     
     
     
     
    function deposit(
      bytes32 tokenId,
      uint value
    )
      external
      payable
      notDeprecated
      existingRAYT(tokenId)
    {

        bytes32 key = _storage.getTokenKey(tokenId);
        notPaused(key);
        verifyValue(key, msg.sender, value);

         
         
         
        IFeeModel(_storage.getContractAddress(FEE_MODEL_CONTRACT)).updateAllowance(key, tokenId);

        uint tokenValueBeforeDeposit;
        uint pricePerShare;

        (tokenValueBeforeDeposit, pricePerShare) = INAVCalculator(_storage.getContractAddress(NAV_CALCULATOR_CONTRACT)).getTokenValue(key, tokenId);

        IPositionManager(_storage.getContractAddress(POSITION_MANAGER_CONTRACT)).increaseTokenCapital(
            key,
            tokenId,
            pricePerShare,
            value
        );

        IStorageWrapper(_storage.getContractAddress(STORAGE_WRAPPER_TWO_CONTRACT)).setAvailableCapital(key, _storage.getAvailableCapital(key) + value);

        emit LogDepositToRAYT(tokenId, value, tokenValueBeforeDeposit);

    }


     
     
     
     
     
     
     
     
     
     
    function redeem(
      bytes32 tokenId,
      uint valueToWithdraw,
      address originalCaller
    )
      external
      notDeprecated
      existingRAYT(tokenId)
      returns(uint)
    {

        address addressToUse = INAVCalculator(_storage.getContractAddress(NAV_CALCULATOR_CONTRACT)).onlyTokenOwner(tokenId, originalCaller, msg.sender);

        uint totalValue;
        uint pricePerShare;

        bytes32 key = _storage.getTokenKey(tokenId);
        (totalValue, pricePerShare) = INAVCalculator(_storage.getContractAddress(NAV_CALCULATOR_CONTRACT)).getTokenValue(key, tokenId);

      uint valueAfterFee = redeem2(
          key,
          tokenId,
          pricePerShare,
          valueToWithdraw,
          totalValue,
          addressToUse
        );

      return valueAfterFee;

    }


      
      
      
      
      
      
      
      
      
      
      
      
      
    function onERC721Received
    (
        address  ,
        address from,
        uint256 tokenId,
        bytes  
    )
        public
        notDeprecated
        returns(bytes4)
    {

        bytes32 convertedTokenId = bytes32(tokenId);

         

         

         
         
        if (
          (IRAYToken(_storage.getContractAddress(RAY_TOKEN_CONTRACT)).tokenExists(convertedTokenId)) &&
          (msg.sender == _storage.getContractAddress(RAY_TOKEN_CONTRACT))
        ) {

            bytes32 key = _storage.getTokenKey(convertedTokenId);

            uint totalValue;
            uint pricePerShare;
            uint valueAfterFee;
            (totalValue, pricePerShare) = INAVCalculator(_storage.getContractAddress(NAV_CALCULATOR_CONTRACT)).getTokenValue(key, convertedTokenId);

             

             
             
             
             
             
             
             
             
             
             
             
             
             

             
             
             
             
             
             
            if (totalValue > 0) {

               
               
               
              IOracle(_storage.getContractAddress(ORACLE_CONTRACT)).withdrawFromProtocols(key, totalValue, totalValue);

              valueAfterFee = IFeeModel(_storage.getContractAddress(FEE_MODEL_CONTRACT)).takeFee(key, convertedTokenId, totalValue);

              IPositionManager(_storage.getContractAddress(POSITION_MANAGER_CONTRACT)).updateTokenUponWithdrawal(
                  key,
                  convertedTokenId,
                  totalValue,
                  pricePerShare,
                  _storage.getTokenShares(key, convertedTokenId),
                  INAVCalculator(_storage.getContractAddress(NAV_CALCULATOR_CONTRACT)).getPortfolioUnrealizedYield(key)
              );

            }

             
            IStorageWrapper(_storage.getContractAddress(STORAGE_WRAPPER_TWO_CONTRACT)).deleteTokenValues(key, convertedTokenId);

            IRAYToken(_storage.getContractAddress(RAY_TOKEN_CONTRACT)).burn(tokenId);

            emit LogBurnRAYT(convertedTokenId, from, valueAfterFee, totalValue);

             
            
            
            _transferFunds(key, from, valueAfterFee);

        }

        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }


     


     
     
     
     
     
     
     
     
     
     
     
    function lend(
      bytes32 key,
      bytes32 opportunityKey,
      address opportunity,
      uint value,
      bool addAC
    )
      external
      onlyOracle
      isValidPortfolio(key)
       
    {

        if (addAC) {

           
           
          IStorageWrapper(_storage.getContractAddress(STORAGE_WRAPPER_TWO_CONTRACT)).setAvailableCapital(key, _storage.getAvailableCapital(key) - value);  

        }

        _lend(key, opportunityKey, opportunity, value);
    }


     
     
     
     
     
     
     
     
     
     
     
    function withdraw(
      bytes32 key,
      bytes32 opportunityKey,
      address opportunity,
      uint value,
      bool addAC
    )
      external
      onlyOracle
      isValidPortfolio(key)
       
    {  

         
         
         
        if (addAC) {

          IStorageWrapper(_storage.getContractAddress(STORAGE_WRAPPER_TWO_CONTRACT)).setAvailableCapital(key, _storage.getAvailableCapital(key) + value);  

        }

        _withdraw(key, opportunityKey, opportunity, value);

    }


     


     
     
     
     
    function transferFunds(
      bytes32 key,
      address beneficiary,
      uint value
    )
      external
      onlyAdmin
    {

      _transferFunds(key, beneficiary, value);

    }


     
     
     
     
     
     
    function approve(
      address token,
      address beneficiary,
      uint amount
    )
      external
      onlyAdmin
    {

      require(
        IERC20(token).approve(beneficiary, amount),
        "#PortfolioMananger approve: Approval of ERC20 Token failed"
      );

    }


     
     
     
     
     
     
    function setApprovalForAll(
      address token,
      address to,
      bool approved
    )
      external
      onlyAdmin
    {

      IERC721(token).setApprovalForAll(to, approved);

    }


    function setDeprecated(bool value) external onlyAdmin {

        deprecated = value;

    }


     


     
     
     
     
     
     
     
     
     
    function _lend(
      bytes32 key,
      bytes32 opportunityKey,
      address opportunity,
      uint value
    )
      internal
      notDeprecated
      isValidOpportunity(key, opportunityKey)
      isCorrectAddress(opportunityKey, opportunity)
    {

       
      notPaused(key);
       

      bytes32 tokenId = _storage.getOpportunityToken(key, opportunityKey);
      address principalAddress = _storage.getPrincipalAddress(key);
      bool isERC20;
      uint payableValue;
      (isERC20, payableValue) =  INAVCalculator(_storage.getContractAddress(NAV_CALCULATOR_CONTRACT)).calculatePayableAmount(principalAddress, value);

      if (tokenId == bytes32(0)) {  

          tokenId = IOpportunityManager(_storage.getContractAddress(OPPORTUNITY_MANAGER_CONTRACT)).buyPosition.value(payableValue)(
            opportunityKey,
            address(this),
            opportunity,
            principalAddress,
            value,
            isERC20
          );

          IStorageWrapper(_storage.getContractAddress(STORAGE_WRAPPER_TWO_CONTRACT)).setOpportunityToken(key, opportunityKey, tokenId);  

          emit LogPurchaseOpportunityToken(tokenId, key);

      } else {  

          IOpportunityManager(_storage.getContractAddress(OPPORTUNITY_MANAGER_CONTRACT)).increasePosition.value(payableValue)(
            opportunityKey,
            tokenId,
            opportunity,
            principalAddress,
            value,
            isERC20
          );

      }

    }


     
     
     
     
     
     
     
     
     
    function _withdraw(
      bytes32 key,
      bytes32 opportunityKey,
      address opportunity,
      uint value
    )
      internal
      notDeprecated  
      isValidOpportunity(key, opportunityKey)
      isCorrectAddress(opportunityKey, opportunity)
    {

        uint yield = INAVCalculator(_storage.getContractAddress(NAV_CALCULATOR_CONTRACT)).getOpportunityYield(key, opportunityKey, value);

        bytes32 tokenId = _storage.getOpportunityToken(key, opportunityKey);
        address principalAddress = _storage.getPrincipalAddress(key);

        IOpportunityManager(_storage.getContractAddress(OPPORTUNITY_MANAGER_CONTRACT)).withdrawPosition(
          opportunityKey,
          tokenId,
          opportunity,
          principalAddress,
          value,
          _storage.getIsERC20(principalAddress)
         );

        if (yield > 0) {

          INAVCalculator(_storage.getContractAddress(NAV_CALCULATOR_CONTRACT)).updateYield(key, yield);

        }

    }


     
     
     
     
     
     
     
     
    function redeem2(
      bytes32 key,
      bytes32 tokenId,
      uint pricePerShare,
      uint valueToWithdraw,
      uint totalValue,
      address addressToUse
    )
      internal
      returns(uint)
    {

      address beneficiary = IPositionManager(_storage.getContractAddress(POSITION_MANAGER_CONTRACT)).verifyWithdrawer(
          key,
          tokenId,
          _storage.getContractAddress(RAY_TOKEN_CONTRACT),
          addressToUse,  
          pricePerShare,
          valueToWithdraw,
          totalValue
      );

      valueToWithdraw += IOracle(_storage.getContractAddress(ORACLE_CONTRACT)).withdrawFromProtocols(key, valueToWithdraw, totalValue);

       
       
      uint valueAfterFee = IFeeModel(_storage.getContractAddress(FEE_MODEL_CONTRACT)).takeFee(key, tokenId, valueToWithdraw);

      redeem3(key, tokenId, valueToWithdraw, pricePerShare);

      emit LogWithdrawFromRAYT(tokenId, valueAfterFee, totalValue);

      _transferFunds(key, beneficiary, valueAfterFee);

      return valueAfterFee;

    }


     
     
     
     
     
     
     
    function redeem3(
      bytes32 key,
      bytes32 tokenId,
      uint valueToWithdraw,
      uint pricePerShare
    )
      internal
    {

      IPositionManager(_storage.getContractAddress(POSITION_MANAGER_CONTRACT)).updateTokenUponWithdrawal(
          key,
          tokenId,
          valueToWithdraw,
          pricePerShare,
          _storage.getTokenShares(key, tokenId),
          INAVCalculator(_storage.getContractAddress(NAV_CALCULATOR_CONTRACT)).getPortfolioUnrealizedYield(key)
      );

    }


     
     
     
     
     
    function _transferFunds(
      bytes32 key,
      address beneficiary,
      uint value
    )
      internal
    {

      address principalAddress = _storage.getPrincipalAddress(key);

      if (_storage.getIsERC20(principalAddress)) {

        require(
          IERC20(principalAddress).transfer(beneficiary, value),
          "#PortfolioMananger _transferFunds(): Transfer of ERC20 Token failed"
        );

      } else {

        beneficiary.transfer(value);

      }

    }


     
     
     
     
     
     
     
    function verifyValue(
      bytes32 key,
      address funder,
      uint inputValue
    )
      internal
    {

      address principalAddress = _storage.getPrincipalAddress(key);

      if (_storage.getIsERC20(principalAddress)) {

        require(
          IERC20(principalAddress).transferFrom(funder, address(this), inputValue),
          "#PortfolioMananger verifyValue: TransferFrom of ERC20 Token failed"
        );

      } else {

        require(
          inputValue == msg.value,
          "#PortfolioMananger verifyValue(): ETH value sent does not match input value");

      }

    }


     
     
     
    function notPaused(bytes32 key) internal view {

      require(
             _storage.getPausedMode(name) == false &&
             _storage.getPausedMode(key) == false,
             "#PortfolioMananger notPaused: In withdraw mode - this function has been paused"
         );

    }


     


    function fallbackClaim(
      uint value,
      address principalToken,
      bool isERC20
    )
      external
      onlyGovernance
    {

      if (isERC20) {

        require(
          IERC20(principalToken).transfer(_storage.getGovernanceWallet(), value),
         "PortfolioManager fallbackClaim(): ERC20 Transfer failed"
       );

      } else {

        _storage.getGovernanceWallet().transfer(value);

      }

    }

}

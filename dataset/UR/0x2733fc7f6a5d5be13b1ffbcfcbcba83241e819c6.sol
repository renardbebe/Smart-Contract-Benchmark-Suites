 

pragma solidity ^0.4.19;

contract DigixConstants {
   
  uint256 constant SECONDS_IN_A_DAY = 24 * 60 * 60;

   
  uint256 constant ASSET_EVENT_CREATED_VENDOR_ORDER = 1;
  uint256 constant ASSET_EVENT_CREATED_TRANSFER_ORDER = 2;
  uint256 constant ASSET_EVENT_CREATED_REPLACEMENT_ORDER = 3;
  uint256 constant ASSET_EVENT_FULFILLED_VENDOR_ORDER = 4;
  uint256 constant ASSET_EVENT_FULFILLED_TRANSFER_ORDER = 5;
  uint256 constant ASSET_EVENT_FULFILLED_REPLACEMENT_ORDER = 6;
  uint256 constant ASSET_EVENT_MINTED = 7;
  uint256 constant ASSET_EVENT_MINTED_REPLACEMENT = 8;
  uint256 constant ASSET_EVENT_RECASTED = 9;
  uint256 constant ASSET_EVENT_REDEEMED = 10;
  uint256 constant ASSET_EVENT_FAILED_AUDIT = 11;
  uint256 constant ASSET_EVENT_ADMIN_FAILED = 12;
  uint256 constant ASSET_EVENT_REMINTED = 13;

   
  uint256 constant ROLE_ZERO_ANYONE = 0;
  uint256 constant ROLE_ROOT = 1;
  uint256 constant ROLE_VENDOR = 2;
  uint256 constant ROLE_XFERAUTH = 3;
  uint256 constant ROLE_POPADMIN = 4;
  uint256 constant ROLE_CUSTODIAN = 5;
  uint256 constant ROLE_AUDITOR = 6;
  uint256 constant ROLE_MARKETPLACE_ADMIN = 7;
  uint256 constant ROLE_KYC_ADMIN = 8;
  uint256 constant ROLE_FEES_ADMIN = 9;
  uint256 constant ROLE_DOCS_UPLOADER = 10;
  uint256 constant ROLE_KYC_RECASTER = 11;
  uint256 constant ROLE_FEES_DISTRIBUTION_ADMIN = 12;

   
  uint256 constant STATE_ZERO_UNDEFINED = 0;
  uint256 constant STATE_CREATED = 1;
  uint256 constant STATE_VENDOR_ORDER = 2;
  uint256 constant STATE_TRANSFER = 3;
  uint256 constant STATE_CUSTODIAN_DELIVERY = 4;
  uint256 constant STATE_MINTED = 5;
  uint256 constant STATE_AUDIT_FAILURE = 6;
  uint256 constant STATE_REPLACEMENT_ORDER = 7;
  uint256 constant STATE_REPLACEMENT_DELIVERY = 8;
  uint256 constant STATE_RECASTED = 9;
  uint256 constant STATE_REDEEMED = 10;
  uint256 constant STATE_ADMIN_FAILURE = 11;

   
  bytes32 constant CONTRACT_INTERACTIVE_ASSETS_EXPLORER = "i:asset:explorer";
  bytes32 constant CONTRACT_INTERACTIVE_DIGIX_DIRECTORY = "i:directory";
  bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE = "i:mp";
  bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE_ADMIN = "i:mpadmin";
  bytes32 constant CONTRACT_INTERACTIVE_POPADMIN = "i:popadmin";
  bytes32 constant CONTRACT_INTERACTIVE_PRODUCTS_LIST = "i:products";
  bytes32 constant CONTRACT_INTERACTIVE_TOKEN = "i:token";
  bytes32 constant CONTRACT_INTERACTIVE_BULK_WRAPPER = "i:bulk-wrapper";
  bytes32 constant CONTRACT_INTERACTIVE_TOKEN_CONFIG = "i:token:config";
  bytes32 constant CONTRACT_INTERACTIVE_TOKEN_INFORMATION = "i:token:information";
  bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE_INFORMATION = "i:mp:information";
  bytes32 constant CONTRACT_INTERACTIVE_IDENTITY = "i:identity";

   
  bytes32 constant CONTRACT_CONTROLLER_ASSETS = "c:asset";
  bytes32 constant CONTRACT_CONTROLLER_ASSETS_RECAST = "c:asset:recast";
  bytes32 constant CONTRACT_CONTROLLER_ASSETS_EXPLORER = "c:explorer";
  bytes32 constant CONTRACT_CONTROLLER_DIGIX_DIRECTORY = "c:directory";
  bytes32 constant CONTRACT_CONTROLLER_MARKETPLACE = "c:mp";
  bytes32 constant CONTRACT_CONTROLLER_MARKETPLACE_ADMIN = "c:mpadmin";
  bytes32 constant CONTRACT_CONTROLLER_PRODUCTS_LIST = "c:products";

  bytes32 constant CONTRACT_CONTROLLER_TOKEN_APPROVAL = "c:token:approval";
  bytes32 constant CONTRACT_CONTROLLER_TOKEN_CONFIG = "c:token:config";
  bytes32 constant CONTRACT_CONTROLLER_TOKEN_INFO = "c:token:info";
  bytes32 constant CONTRACT_CONTROLLER_TOKEN_TRANSFER = "c:token:transfer";

  bytes32 constant CONTRACT_CONTROLLER_JOB_ID = "c:jobid";
  bytes32 constant CONTRACT_CONTROLLER_IDENTITY = "c:identity";

   
  bytes32 constant CONTRACT_STORAGE_ASSETS = "s:asset";
  bytes32 constant CONTRACT_STORAGE_ASSET_EVENTS = "s:asset:events";
  bytes32 constant CONTRACT_STORAGE_DIGIX_DIRECTORY = "s:directory";
  bytes32 constant CONTRACT_STORAGE_MARKETPLACE = "s:mp";
  bytes32 constant CONTRACT_STORAGE_PRODUCTS_LIST = "s:products";
  bytes32 constant CONTRACT_STORAGE_GOLD_TOKEN = "s:goldtoken";
  bytes32 constant CONTRACT_STORAGE_JOB_ID = "s:jobid";
  bytes32 constant CONTRACT_STORAGE_IDENTITY = "s:identity";

   
  bytes32 constant CONTRACT_SERVICE_TOKEN_DEMURRAGE = "sv:tdemurrage";
  bytes32 constant CONTRACT_SERVICE_MARKETPLACE = "sv:mp";
  bytes32 constant CONTRACT_SERVICE_DIRECTORY = "sv:directory";

   
  bytes32 constant CONTRACT_DEMURRAGE_FEES_DISTRIBUTOR = "fees:distributor:demurrage";
  bytes32 constant CONTRACT_RECAST_FEES_DISTRIBUTOR = "fees:distributor:recast";
  bytes32 constant CONTRACT_TRANSFER_FEES_DISTRIBUTOR = "fees:distributor:transfer";
}

contract ContractResolver {
  address public owner;
  bool public locked;
  function init_register_contract(bytes32 _key, address _contract_address) public returns (bool _success);
  function unregister_contract(bytes32 _key) public returns (bool _success);
  function get_contract(bytes32 _key) public constant returns (address _contract);
}

contract ResolverClient {

   
  address public resolver;
   
  bytes32 public key;

   
  address public CONTRACT_ADDRESS;

   
   
  modifier if_sender_is(bytes32 _contract) {
    require(msg.sender == ContractResolver(resolver).get_contract(_contract));
    _;
  }

   
  modifier unless_resolver_is_locked() {
    require(is_locked() == false);
    _;
  }

   
   
   
  function init(bytes32 _key, address _resolver)
           internal
           returns (bool _success)
  {
    bool _is_locked = ContractResolver(_resolver).locked();
    if (_is_locked == false) {
      CONTRACT_ADDRESS = address(this);
      resolver = _resolver;
      key = _key;
      require(ContractResolver(resolver).init_register_contract(key, CONTRACT_ADDRESS));
      _success = true;
    }  else {
      _success = false;
    }
  }

   
   
  function destroy()
           public
           returns (bool _success)
  {
    bool _is_locked = ContractResolver(resolver).locked();
    require(!_is_locked);

    address _owner_of_contract_resolver = ContractResolver(resolver).owner();
    require(msg.sender == _owner_of_contract_resolver);

    _success = ContractResolver(resolver).unregister_contract(key);
    require(_success);

    selfdestruct(_owner_of_contract_resolver);
  }

   
   
  function is_locked()
           private
           constant
           returns (bool _locked)
  {
    _locked = ContractResolver(resolver).locked();
  }

   
   
   
  function get_contract(bytes32 _key)
           public
           constant
           returns (address _contract)
  {
    _contract = ContractResolver(resolver).get_contract(_key);
  }
}

 
 
contract Constants {
  address constant NULL_ADDRESS = address(0x0);
  uint256 constant ZERO = uint256(0);
  bytes32 constant EMPTY = bytes32(0x0);
}

 
 
contract ACConditions is Constants {

  modifier not_null_address(address _item) {
    require(_item != NULL_ADDRESS);
    _;
  }

  modifier if_null_address(address _item) {
    require(_item == NULL_ADDRESS);
    _;
  }

  modifier not_null_uint(uint256 _item) {
    require(_item != ZERO);
    _;
  }

  modifier if_null_uint(uint256 _item) {
    require(_item == ZERO);
    _;
  }

  modifier not_empty_bytes(bytes32 _item) {
    require(_item != EMPTY);
    _;
  }

  modifier if_empty_bytes(bytes32 _item) {
    require(_item == EMPTY);
    _;
  }

  modifier not_null_string(string _item) {
    bytes memory _i = bytes(_item);
    require(_i.length > 0);
    _;
  }

  modifier if_null_string(string _item) {
    bytes memory _i = bytes(_item);
    require(_i.length == 0);
    _;
  }

  modifier require_gas(uint256 _requiredgas) {
    require(msg.gas  >= (_requiredgas - 22000));
    _;
  }

  function is_contract(address _contract)
           public
           constant
           returns (bool _is_contract)
  {
    uint32 _code_length;

    assembly {
      _code_length := extcodesize(_contract)
    }

    if(_code_length > 1) {
      _is_contract = true;
    } else {
      _is_contract = false;
    }
  }

  modifier if_contract(address _contract) {
    require(is_contract(_contract) == true);
    _;
  }

  modifier unless_contract(address _contract) {
    require(is_contract(_contract) == false);
    _;
  }
}

contract IdentityStorage {
  function read_user(address _user) public constant returns (uint256 _id_expiration, bytes32 _doc);
}

contract MarketplaceStorage {
  function read_user(address _user) public constant returns (uint256 _daily_dgx_limit, uint256 _total_purchased_today);
  function read_user_daily_limit(address _user) public constant returns (uint256 _daily_dgx_limit);
  function read_config() public constant returns (uint256 _global_daily_dgx_ng_limit, uint256 _minimum_purchase_dgx_ng, uint256 _maximum_block_drift, address _payment_collector);
  function read_dgx_inventory_balance_ng() public constant returns (uint256 _balance);
  function read_total_number_of_purchases() public constant returns (uint256 _total_number_of_purchases);
  function read_total_number_of_user_purchases(address _user) public constant returns (uint256 _total_number_of_user_purchases);
  function read_purchase_at_index(uint256 _index) public constant returns (address _recipient, uint256 _timestamp, uint256 _amount, uint256 _price);
  function read_user_purchase_at_index(address _user, uint256 _index) public constant returns (address _recipient, uint256 _timestamp, uint256 _amount, uint256 _price);
  function read_total_global_purchased_today() public constant returns (uint256 _total_global_purchased_today);
  function read_total_purchased_today(address _user) public constant returns (uint256 _total_purchased_today);
  function read_max_dgx_available_daily() public constant returns (uint256 _max_dgx_available_daily);
  function read_price_floor() public constant returns (uint256 _price_floor_wei_per_dgx_mg);
}

contract MarketplaceControllerCommon {
}

contract MarketplaceController {
}

contract MarketplaceAdminController {
}

contract MarketplaceCommon is ResolverClient, ACConditions, DigixConstants {

  function marketplace_admin_controller()
           internal
           constant
           returns (MarketplaceAdminController _contract)
  {
    _contract = MarketplaceAdminController(get_contract(CONTRACT_CONTROLLER_MARKETPLACE_ADMIN));
  }

  function marketplace_storage()
           internal
           constant
           returns (MarketplaceStorage _contract)
  {
    _contract = MarketplaceStorage(get_contract(CONTRACT_STORAGE_MARKETPLACE));
  }

  function marketplace_controller()
           internal
           constant
           returns (MarketplaceController _contract)
  {
    _contract = MarketplaceController(get_contract(CONTRACT_CONTROLLER_MARKETPLACE));
  }
}

 
 
 
contract MarketplaceInformation is MarketplaceCommon {

  function MarketplaceInformation(address _resolver) public
  {
    require(init(CONTRACT_INTERACTIVE_MARKETPLACE_INFORMATION, _resolver));
  }

  function identity_storage()
           internal
           constant
           returns (IdentityStorage _contract)
  {
    _contract = IdentityStorage(get_contract(CONTRACT_STORAGE_IDENTITY));
  }

   
   
   
   
   
   
   
   
   
   
  function getUserInfoAndConfig(address _user)
           public
           constant
           returns (uint256 _user_daily_dgx_limit, uint256 _user_id_expiration, uint256 _user_total_purchased_today,
                    uint256 _config_global_daily_dgx_ng_limit, uint256 _config_maximum_block_drift,
                    uint256 _config_minimum_purchase_dgx_ng, address _config_payment_collector)
  {
    (_user_daily_dgx_limit, _user_total_purchased_today) =
      marketplace_storage().read_user(_user);

    (_user_id_expiration,) = identity_storage().read_user(_user);

    (_config_global_daily_dgx_ng_limit, _config_minimum_purchase_dgx_ng, _config_maximum_block_drift, _config_payment_collector) =
      marketplace_storage().read_config();
  }

   
   
   
   
   
   
   
  function getConfig()
           public
           constant
           returns (uint256 _global_daily_dgx_ng_limit, uint256 _minimum_purchase_dgx_ng, uint256 _maximum_block_drift, address _payment_collector)
  {
     (_global_daily_dgx_ng_limit, _minimum_purchase_dgx_ng, _maximum_block_drift, _payment_collector) =
       marketplace_storage().read_config();
  }

   
   
   
   
   
  function userMaximumPurchaseAmountNg(address _user)
           public
           constant
           returns (uint256 _maximum_purchase_amount_ng)
  {
    _maximum_purchase_amount_ng = marketplace_storage().read_user_daily_limit(_user);
  }

   
   
   
   
  function availableDgxNg()
           public
           constant
           returns (uint256 _available_ng)
  {
    _available_ng = marketplace_storage().read_dgx_inventory_balance_ng();
  }

   
   
  function readTotalNumberOfPurchases()
           public
           constant
           returns (uint256 _total_number_of_purchases)
  {
    _total_number_of_purchases = marketplace_storage().read_total_number_of_purchases();
  }

   
   
   
  function readTotalNumberOfUserPurchases(address _user)
           public
           constant
           returns (uint256 _total_number_of_user_purchases)
  {
    _total_number_of_user_purchases = marketplace_storage().read_total_number_of_user_purchases(_user);
  }

   
   
   
   
   
   
   
   
  function readPurchaseAtIndex(uint256 _index)
           public
           constant
           returns (address _recipient, uint256 _timestamp, uint256 _amount, uint256 _price)
  {
    (_recipient, _timestamp, _amount, _price) = marketplace_storage().read_purchase_at_index(_index);
  }

   
   
   
   
   
   
   
   
  function readUserPurchaseAtIndex(address _user, uint256 _index)
           public
           constant
           returns (address _recipient, uint256 _timestamp, uint256 _amount, uint256 _price)
  {
    (_recipient, _timestamp, _amount, _price) = marketplace_storage().read_user_purchase_at_index(_user, _index);
  }

   
   
  function readGlobalPurchasedToday()
           public
           constant
           returns (uint256 _total_purchased_today)
  {
    _total_purchased_today = marketplace_storage().read_total_global_purchased_today();
  }

   
   
   
  function readUserPurchasedToday(address _user)
           public
           constant
           returns (uint256 _user_total_purchased_today)
  {
    _user_total_purchased_today = marketplace_storage().read_total_purchased_today(_user);
  }

   
   
   
   
   
   
   
   
  function readMarketplaceConfigs()
           public
           constant
           returns (uint256 _global_default_user_daily_limit,
                    uint256 _minimum_purchase_dgx_ng,
                    uint256 _maximum_block_drift,
                    address _payment_collector,
                    uint256 _max_dgx_available_daily,
                    uint256 _price_floor_wei_per_dgx_mg)
  {
    (_global_default_user_daily_limit, _minimum_purchase_dgx_ng, _maximum_block_drift, _payment_collector)
      = marketplace_storage().read_config();
    _max_dgx_available_daily = marketplace_storage().read_max_dgx_available_daily();
    _price_floor_wei_per_dgx_mg = marketplace_storage().read_price_floor();
  }

}
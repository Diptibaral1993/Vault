// SPDX-License-Identifier: GPL-3.0
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _contractOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function contractOwner() public view virtual returns (address) {
        return _contractOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_contractOwner, address(0));
        _setContractOwner(address(0));
    }

    modifier onlyOwner() {
        require(contractOwner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(_contractOwner, newOwner);
        _setContractOwner(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        emit OwnershipTransferred(_contractOwner, newOwner);
        _setContractOwner(newOwner);
    }

    function _setContractOwner(address newOwner) internal {
        _contractOwner = newOwner;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20OwnToken {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function addUser(address _addressToWhitelist) external;
    function verifyUser(address _whitelistedAddress) external view returns(bool);
    function removeFromWhitelist(address[] calldata toRemoveAddresses)external;
}

contract vault is Ownable
{

    struct strReward { 
        address nativeToken;
        uint256 amount;
        uint256 lastDepositTime;
        
    }

    mapping(address=>strReward) public _Reward;

    struct _usrReward { 
        uint256 amount;
        uint256 withdrawn;
        uint256 lastRewardBalance;
        uint256 lastWithdrawTime;
        
    }

    mapping(address=>mapping(address=>_usrReward)) public usrReward;

    constructor(){

    }

    function depositReward(address _rewardTokenAddress,address _ERC20tokenaddress,uint256 _amount) external virtual onlyOwner returns(bool){
        
        uint256 newrewardamt=_Reward[_ERC20tokenaddress].amount + _amount;
        
        _Reward[_ERC20tokenaddress]=strReward(_rewardTokenAddress,newrewardamt,block.timestamp);
        
        IERC20(_rewardTokenAddress).transferFrom(msg.sender,address(this),_amount);
        
        return true;
    }

    function withdrawReward(address _ERC20tokenaddress) public returns (bool){
        require(IERC20OwnToken(_ERC20tokenaddress).verifyUser(msg.sender),"Not Whitelist User");
        setRewardInternal(_ERC20tokenaddress,msg.sender);
        _usrReward storage reward=usrReward[_ERC20tokenaddress][msg.sender];
        require(reward.amount!=0,"You dont have any reward to withdraw");
        
        uint256 tempreward=reward.amount;

        reward.withdrawn+=reward.amount;
        reward.amount=0;
        reward.lastWithdrawTime=block.timestamp;
        
        IERC20(_Reward[_ERC20tokenaddress].nativeToken).transfer(msg.sender,tempreward);
        return true;
    }

    function setRewardInternal(address _ERC20tokenaddress,address _wallet) internal returns (bool){
        require(_wallet!=address(0),"Invalid Wallet");
        uint256 lastdeposittime=_Reward[_ERC20tokenaddress].lastDepositTime;

        uint256 _amount=IERC20OwnToken(_ERC20tokenaddress).balanceOf(_wallet);
        uint256 _totalsupply=IERC20OwnToken(_ERC20tokenaddress).totalSupply();

        _usrReward storage reward=usrReward[_ERC20tokenaddress][_wallet];
        if(lastdeposittime!=0)
        {
            uint256 lastWithdrawtime=reward.lastWithdrawTime;
            if(lastdeposittime<lastWithdrawtime || lastWithdrawtime==0)
            {
                if(_Reward[_ERC20tokenaddress].amount==reward.lastRewardBalance)
                {
                    reward.amount+=((_Reward[_ERC20tokenaddress].amount) *(_amount*100)/_totalsupply)/100;
                    reward.lastRewardBalance=_Reward[_ERC20tokenaddress].amount;
                }
                else 
                {
                    reward.amount+=((_Reward[_ERC20tokenaddress].amount-reward.lastRewardBalance) *(_amount*100)/_totalsupply)/100;
                    reward.lastRewardBalance=_Reward[_ERC20tokenaddress].amount;
                }
                
            }
            return true;
        }
        else 
        {
            return false;
        }
    }

    function setReward(address _wallet,uint256 _amount,uint256 _totalsupply) external returns (bool){
        require(_wallet!=address(0),"Invalid Wallet");
        uint256 lastdeposittime=_Reward[msg.sender].lastDepositTime;
        _usrReward storage reward=usrReward[msg.sender][_wallet];
        if(lastdeposittime!=0)
        {
            uint256 lastWithdrawtime=reward.lastWithdrawTime;
            if(lastdeposittime<lastWithdrawtime || lastWithdrawtime==0)
            {
                if(_Reward[msg.sender].amount==reward.lastRewardBalance){
                    reward.amount+=((_Reward[msg.sender].amount) *(_amount*100)/_totalsupply)/100;
                    reward.lastRewardBalance=_Reward[msg.sender].amount;
                }
                else 
                {
                    reward.amount+=((_Reward[msg.sender].amount-reward.lastRewardBalance) *(_amount*100)/_totalsupply)/100;
                    reward.lastRewardBalance=_Reward[msg.sender].amount;
                }
                
            }
            return true;
        }
        else 
        {
            return false;
        }
    }

    function checkWalletReward(address _token) public view returns (uint256){

        _usrReward storage reward=usrReward[_token][msg.sender];
        uint256 balance=IERC20OwnToken(_token).balanceOf(msg.sender);
        uint256 totalsupply=IERC20OwnToken(_token).totalSupply();
        if(reward.lastRewardBalance==_Reward[_token].amount)
        {
            return (_Reward[_token].amount *(balance*100)/totalsupply)/100;
         
        }
        else 
        {
            return ((_Reward[_token].amount-reward.lastRewardBalance) *(balance*100)/totalsupply)/100;
         
        }
               
    }

    function checkWalletRewardAdmin(address _token,address _wallet) public view onlyOwner returns (uint256){

        _usrReward storage reward=usrReward[_token][_wallet];
        uint256 balance=IERC20OwnToken(_token).balanceOf(_wallet);
        uint256 totalsupply=IERC20OwnToken(_token).totalSupply();

        if(reward.lastRewardBalance==_Reward[_token].amount)
        {
            return ((_Reward[_token].amount) *(balance*100)/totalsupply)/100;
         
        }
        else 
        {
            return ((_Reward[_token].amount-reward.lastRewardBalance) *(balance*100)/totalsupply)/100;
         
        }
        
                
    }


    function withdrawAdmin(address _token) external virtual onlyOwner returns (bool){
        IERC20(_Reward[_token].nativeToken).transfer(msg.sender,address(this).balance);
        return true;
    }


}


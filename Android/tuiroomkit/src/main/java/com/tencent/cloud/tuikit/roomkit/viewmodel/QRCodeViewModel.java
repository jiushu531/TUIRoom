package com.tencent.cloud.tuikit.roomkit.viewmodel;

import android.Manifest;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.graphics.Bitmap;
import android.widget.Toast;

import com.tencent.cloud.tuikit.roomkit.R;
import com.tencent.cloud.tuikit.roomkit.model.entity.RoomInfo;
import com.tencent.cloud.tuikit.roomkit.model.manager.RoomEngineManager;
import com.tencent.cloud.tuikit.roomkit.model.utils.CommonUtils;
import com.tencent.cloud.tuikit.roomkit.model.utils.SaveBitMap;
import com.tencent.cloud.tuikit.roomkit.view.component.QRCodeView;
import com.tencent.qcloud.tuicore.permission.PermissionCallback;
import com.tencent.qcloud.tuicore.permission.PermissionRequester;

public class QRCodeViewModel {
    private Context    mContext;
    private QRCodeView mQRCodeView;
    private SaveBitMap mSaveBitMap;

    public QRCodeViewModel(Context context, QRCodeView view) {
        mContext = context;
        mQRCodeView = view;
    }

    public RoomInfo getRoomInfo() {
        return RoomEngineManager.sharedInstance(mContext).getRoomStore().roomInfo;
    }

    public void saveQRCodeToAlbum(final Bitmap bitmap) {
        PermissionCallback callback = new PermissionCallback() {
            @Override
            public void onGranted() {
                if (mSaveBitMap == null) {
                    mSaveBitMap = new SaveBitMap();
                }
                mSaveBitMap.saveToAlbum(mContext, bitmap);
            }
        };

        PermissionRequester.newInstance(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                .title(mContext.getString(R.string.tuiroomkit_permission_storage_reason_title,
                        CommonUtils.getAppName(mContext)))
                .description(mContext.getString(R.string.tuiroomkit_permission_storage_reason))
                .settingsTip(mContext.getString(R.string.tuiroomkit_tips_start_storage))
                .callback(callback)
                .request();
    }

    public void copyContentToClipboard(String content, String toast) {
        ClipboardManager cm = (ClipboardManager) mContext.getSystemService(Context.CLIPBOARD_SERVICE);
        ClipData mClipData = ClipData.newPlainText("Label", content);
        cm.setPrimaryClip(mClipData);
        Toast.makeText(mContext, toast, Toast.LENGTH_SHORT).show();
    }

    public void horizontalAnimation(boolean isShowingView) {
        CommonUtils.horizontalAnimation(mQRCodeView, isShowingView);
    }
}
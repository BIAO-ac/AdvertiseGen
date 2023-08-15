# coding utf-8
import os
from minio import Minio


class MinioManager(object):
    
    def __init__(self, endpoint, access_key, secret_key, secure=True):
        self.minioClient = Minio(
            endpoint=endpoint,
            access_key=access_key,
            secret_key=secret_key,
            secure=secure,
        )

    def bucket_exists(self, bucket_name):
        try:
            return self.minioClient.bucket_exists(bucket_name)
        except Exception as error:
            print(error)
            return None
        
    def create_bucket(self, bucket_name, object_lock=False):
        if self.bucket_exists(bucket_name) is True:
            return True
        try:
            self.minioClient.make_bucket(
                bucket_name=bucket_name,
                object_lock=object_lock
            )
        except Exception as error:
            print(error)
            return False
        return True
    
    def list_buckets(self):
        try:
            return self.minioClient.list_buckets()
        except Exception as error:
            print(error)
            return None
    
    def remove_bucket(self, bucket_name):
        if self.bucket_exists(bucket_name) is False:
            return True
        try:
            self.minioClient.remove_bucket(bucket_name)
        except Exception as error:
            print(error)
            return False
        return True
    
    def put_object(self, file_path, bucket_name, object_name):
        try:
            file_size = os.stat(file_path).st_size
            file = open(file_path, "rb")
            self.minioClient.put_object(bucket_name, object_name, file, file_size)
            file.close()
        except Exception as error:
            print(error)
            return False
        return True
    
    def fput_object(self, file_path, bucket_name, object_name):
        try:
            self.minioClient.fput_object(bucket_name, object_name, file_path)
        except Exception as error:
            print(error)
            return False
        return True
    
    def get_object(self, bucket_name, object_name, file_path=None):
        try:
            resp = self.minioClient.get_object(bucket_name, object_name)
            if file_path is not None:
                file = open("file_path", "wb")
                for line in resp:
                    file.write(line)
                file.close()
        except Exception as error:
            print(error)
            return None

    def fget_object(self, bucket_name, object_name, file_path):
        try:
            self.minioClient.fget_object(bucket_name, object_name, file_path)
        except Exception as error:
            print(error)
            return False
        return True
                            
    def remove_object(self, bucket_name, object_name, version_id=None):
        try:
            self.minioClient.remove_object(bucket_name, object_name, version_id)
        except Exception as error:
            print(error)
            return False
        return True         
    
    def get_object_url(self, bucket_name, object_name):
        try:
            return self.minioClient.presigned_get_object(bucket_name, object_name)
        except Exception as error:
            print(error)
            return None
        
    def list_objects(self, bucket_name):
        try:
            return self.minioClient.list_objects(bucket_name)
        except Exception as error:
            print(error)
            return None


if __name__ == "__main__":

    # demo file generation
    local_file_path = "demo_file.pth"
    file = open(local_file_path, "w")
    file.write("123")
    file.close()

    minio = MinioManager(
        endpoint='minio-12256-9000.vk.dev.danlu.netease.com',
        access_key='CR4uB62eEEKLWMy4',
        secret_key='ozGkaNseRGhEZdI6qs7SNCNiGgsdrCJq',
        secure=False,  # must be False
    )
    bucket_name = "ruiku"

    # bucket related
    print(minio.bucket_exists(bucket_name))
    minio.create_bucket(bucket_name)
    print(minio.bucket_exists(bucket_name))
    minio.remove_bucket(bucket_name)
    print(minio.bucket_exists(bucket_name))
    minio.create_bucket(bucket_name)

    # list query
    print(minio.list_buckets())  # return list

    # upload related
    minio.put_object(local_file_path, bucket_name, object_name=local_file_path)
    minio.fput_object(local_file_path, bucket_name, object_name="fput_"+local_file_path)

    # list query
    print(list(minio.list_objects(bucket_name)))  # return iterator

    # download related
    resp = minio.get_object(bucket_name, object_name=local_file_path)  # return urllib3 HTTPResponse object
    resp = minio.get_object(bucket_name, object_name=local_file_path, file_path="./get_vgg16.pth")  # also saved to file
    minio.fget_object(bucket_name, object_name="fput_"+local_file_path, file_path="./fget_vgg16.pth")  # only saved to file

    # download url related
    url = minio.get_object_url(bucket_name, local_file_path)
    print(url)

    # list query
    print(minio.list_buckets())  # return list
    print(list(minio.list_objects(bucket_name)))  # return iterator

    # delete related
    minio.remove_object(bucket_name, local_file_path)
    minio.remove_object(bucket_name, "fput_"+local_file_path)
    minio.remove_bucket(bucket_name)
